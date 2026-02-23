#!/bin/bash

# ================================
# Azure Terraform Backend Setup
# ================================

RESOURCE_GROUP_NAME="terraform-state-rg"
LOCATION="eastus"
STAGE_SA_ACCOUNT="tfstagebackend2026shyam"
DEV_SA_ACCOUNT="tfdevbackend2026shyam"
CONTAINER_NAME="tfstate"

echo "Checking Azure login..."
az account show > /dev/null 2>&1 || az login

echo "Creating Resource Group..."
az group create \
  --name $RESOURCE_GROUP_NAME \
  --location $LOCATION

echo "Creating Storage Account for STAGE..."
az storage account create \
  --resource-group $RESOURCE_GROUP_NAME \
  --name $STAGE_SA_ACCOUNT \
  --sku Standard_LRS \
  --encryption-services blob

echo "Creating Storage Account for DEV..."
az storage account create \
  --resource-group $RESOURCE_GROUP_NAME \
  --name $DEV_SA_ACCOUNT \
  --sku Standard_LRS \
  --encryption-services blob

echo "Assigning RBAC role (Storage Blob Data Contributor)..."

USER_OBJECT_ID=$(az ad signed-in-user show --query id -o tsv)

# Assign role for STAGE
az role assignment create \
  --role "Storage Blob Data Contributor" \
  --assignee $USER_OBJECT_ID \
  --scope $(az storage account show \
      --name $STAGE_SA_ACCOUNT \
      --resource-group $RESOURCE_GROUP_NAME \
      --query id -o tsv) \
  2>/dev/null

# Assign role for DEV
az role assignment create \
  --role "Storage Blob Data Contributor" \
  --assignee $USER_OBJECT_ID \
  --scope $(az storage account show \
      --name $DEV_SA_ACCOUNT \
      --resource-group $RESOURCE_GROUP_NAME \
      --query id -o tsv) \
  2>/dev/null

echo "Waiting 15 seconds for RBAC propagation..."
sleep 15

echo "Creating Blob Container for STAGE..."
az storage container create \
  --name $CONTAINER_NAME \
  --account-name $STAGE_SA_ACCOUNT \
  --auth-mode login

echo "Creating Blob Container for DEV..."
az storage container create \
  --name $CONTAINER_NAME \
  --account-name $DEV_SA_ACCOUNT \
  --auth-mode login

echo "======================================="
echo "Terraform Backend Infrastructure Ready!"
echo "======================================="
