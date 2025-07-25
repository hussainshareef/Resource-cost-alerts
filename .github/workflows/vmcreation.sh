name: Create Azure VM

on:
  workflow_dispatch:

jobs:
  provision:
    runs-on: ubuntu-latest
    env:
      AZURE_CLIENT_ID: ${{ secrets.ARM_CLIENT_ID }}
      AZURE_CLIENT_SECRET: ${{ secrets.ARM_CLIENT_SECRET }}
      AZURE_TENANT_ID: ${{ secrets.ARM_TENANT_ID }}
      AZURE_SUBSCRIPTION_ID: ${{ secrets.ARM_SUBSCRIPTION_ID }}
      
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Log in to Azure using environment variables
        run: |
          az login --service-principal \
            --username "$ARM_CLIENT_ID" \
            --password "$ARM_CLIENT_SECRET" \
            --tenant "$ARM_TENANT_ID"
          
          az account set --subscription "$ARM_SUBSCRIPTION_ID"

      - name: Create resource group
        run: |
          az group create --name myrg --location centralindia

      - name: Create vnet and subnet
        run: |
          az network vnet create \
            --resource-group myrg \
            --name myvnet \
            --address-prefixes 10.0.0.0/16 \
            --subnet-name mysubnet \
            --subnet-prefixes 10.0.1.0/24

      - name: Create another subnet
        run: |
          az network vnet subnet create \
            --resource-group myrg \
            --vnet-name myvnet \
            --name mysubnet1 \
            --address-prefixes 10.0.2.0/24

      - name: Create network security group
        run: |
          az network nsg create --resource-group myrg --name mynsg

      - name: Create NSG rule for RDP
        run: |
          az network nsg rule create \
            --resource-group myrg \
            --nsg-name mynsg \
            --name Allow-rdp \
            --priority 1001 \
            --access Allow \
            --protocol TCP \
            --direction Inbound \
            --source-address-prefixes "*" \
            --source-port-ranges "*" \
            --destination-port-ranges 3389 \
            --destination-address-prefixes "*"

      - name: Create public IP
        run: |
          az network public-ip create --resource-group myrg --name mypubip

      - name: Create NIC and attach subnet
        run: |
          az network nic create \
            --resource-group myrg \
            --name mynic \
            --vnet-name myvnet \
            --subnet mysubnet \
            --network-security-group mynsg \
            --public-ip-address mypubip

      - name: Create VM and attach NIC
        run: |
          az vm create \
            --resource-group myrg \
            --name myvm \
            --nics mynic \
            --image Win2019Datacenter \
            --size Standard_B2ms \
            --admin-username azureuser \
            --admin-password ${{ secrets.AZURE_ADMIN_PASSWORD }}

      - name: List public IP for VM login
        run: |
          az vm list-ip-addresses -g myrg -n myvm
