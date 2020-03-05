# KK-Data-AI
# Unzip 7z files using Azure Automation Runbooks and Azure Data Factory

I have recently come across a Customer who is migrating On-prem DW workloads to Azure cloud (using Azure Synapse Analytics, Data Factory, Azure Storage, Power BI) and has a scenario where they have a bunch of 7z compressed data files that are being unzipped using a utility installed in a VM for further processing in their data warehouse. Now the Customer is using Azure Data Factory for Orchestrating the data pipelines and would like to do the unzipping of files as part of the end to end workflow.

If you are already working with Data Factory, you might have figured that ADF allows to compress/decompress files in bzip2, gzip, deflate, ZipDeflate formats and there's no easy way to unzip 7z files.

This post is an attempt to help all the Azure data engineers using ADF and come across a similar scenario with 7z compressed files.

Before we dive deep down into the how to, I am assuming that you already know how to provision Azure Data Factory, Azure Automation, Blob Storage.  If not, it's pretty easy to get started.

# High Level workflow to get this done
1. Using ADF, Copy (binary) files from On prem FTP server to a container in Blob Storage
2. Create an Azure Automation Account and Import Module "7Zip4Powershell" 
3. Create a Powershell Runbook - PS script to Download file from Blob Storage, Expand the file and Upload file to Blob Storage.
4. Add a Webhook to the Runbook and copy the URL
5. In ADF pipeline - Use the webhook activity to call the Runbook to execute.


