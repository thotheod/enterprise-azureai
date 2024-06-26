param name string
param location string = resourceGroup().location
param apimSubnetName string
param apimNsgName string
param acaSubnetName string
param acaNsgName string
param appServiceSubnetName string
param appServiceNsgName string

param privateEndpointSubnetName string
param privateEndpointNsgName string
param privateDnsZoneNames array
param tags object = {}
param apimSku string


var webServerFarmDelegation = [
  {
    name: 'Microsoft.Web/serverFarms'
    properties: {
      serviceName: 'Microsoft.Web/serverFarms'
    }
  }
] 

resource apimNsg 'Microsoft.Network/networkSecurityGroups@2020-07-01' = {
  name: apimNsgName
  location: location
  tags: union(tags, { 'azd-service-name': apimNsgName })
  properties: {
    securityRules: [
      {
        name: 'AllowClientToGateway'
        properties: {
            protocol: 'Tcp'
            sourcePortRange: '*'
            destinationPortRange: '443'
            sourceAddressPrefix: 'Internet'
            destinationAddressPrefix: 'VirtualNetwork'
            access: 'Allow'
            priority: 2721
            direction: 'Inbound'
        }
      }
      {
        name: 'AllowAPIMPortal'
        properties: {
            protocol: 'Tcp'
            sourcePortRange: '*'
            destinationPortRange: '3443'
            sourceAddressPrefix: 'ApiManagement'
            destinationAddressPrefix: 'VirtualNetwork'
            access: 'Allow'
            priority: 2731
            direction: 'Inbound'
        }
      }
      {
        name: 'AllowAPIMLoadBalancer'
        properties: {
            protocol: '*'
            sourcePortRange: '*'
            destinationPortRange: '6390'
            sourceAddressPrefix: 'AzureLoadBalancer'
            destinationAddressPrefix: 'VirtualNetwork'
            access: 'Allow'
            priority: 2741
            direction: 'Inbound'
        }
      }
    ]
  }
}

resource acaNsg 'Microsoft.Network/networkSecurityGroups@2022-09-01' = {
  name: acaNsgName
  location: location
  properties: {
    securityRules: []
  }
}

resource appServiceNsg 'Microsoft.Network/networkSecurityGroups@2022-09-01' = {
  name: appServiceNsgName
  location: location
  properties: {
    securityRules: []
  }
}

resource privateEndpointNsg 'Microsoft.Network/networkSecurityGroups@2020-07-01' = {
  name: privateEndpointNsgName
  location: location
  tags: union(tags, { 'azd-service-name': privateEndpointNsgName })
  properties: {
    securityRules: []
  }
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: name
  location: location
  tags: union(tags, { 'azd-service-name': name })
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '10.0.0.0/24'
        }
      }
      {
        name: apimSubnetName
        properties: {
          addressPrefix: '10.0.1.0/24'
          networkSecurityGroup: apimNsg.id == '' ? null : {
            id: apimNsg.id 
          }
          // Needed when using APIM StandardV2 SKU
          delegations: apimSku == 'StandardV2' ? webServerFarmDelegation :  []
        }
      }
      {
        name: privateEndpointSubnetName
        properties: {
          addressPrefix: '10.0.2.0/24'
          networkSecurityGroup: privateEndpointNsg.id == '' ? null : {
            id: privateEndpointNsg.id
          }
        }
      }
      {
        name: acaSubnetName
        properties: {
          addressPrefix: '10.0.3.0/24'
          networkSecurityGroup: acaNsg.id == '' ? null : {
            id: acaNsg.id
          }
          delegations: [
            {
              name: 'Microsoft.App/environments'
              properties: {
                serviceName: 'Microsoft.App/environments'
              }
            }
          ]
          
          
        }
      }
      {
        name: appServiceSubnetName
        properties: {
          addressPrefix: '10.0.4.0/24'
          networkSecurityGroup: appServiceNsg.id == '' ? null : {
            id: appServiceNsg.id
          }
          delegations: webServerFarmDelegation
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: '10.0.5.0/24'
        }
      }
    ]
  }

  resource defaultSubnet 'subnets' existing = {
    name: 'default'
  }

  resource apimSubnet 'subnets' existing = {
    name: apimSubnetName
  }
  
  resource acaSubnet 'subnets' existing = {
    name: acaSubnetName
  }
  
  resource appServiceSubnet 'subnets' existing = {
    name: appServiceSubnetName
  }
  
  resource privateEndpointSubnet 'subnets' existing = {
    name: privateEndpointSubnetName
  }
}

resource privateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = [for privateDnsZoneName in privateDnsZoneNames: {
  name: '${privateDnsZoneName}/privateDnsZoneLink'
  location: 'global'
  properties: {
    virtualNetwork: {
      id: virtualNetwork.id
    }
    registrationEnabled: false
  }
}]

output virtualNetworkId string = virtualNetwork.id
output vnetName string = virtualNetwork.name
output apimSubnetName string = virtualNetwork::apimSubnet.name
output apimSubnetId string = virtualNetwork::apimSubnet.id
output acaSubnetName string = virtualNetwork::acaSubnet.name
output acaSubnetId string = virtualNetwork::acaSubnet.id
output appServiceSubnetName string = virtualNetwork::appServiceSubnet.name
output appServiceSubnetId string = virtualNetwork::appServiceSubnet.id
output privateEndpointSubnetName string = virtualNetwork::privateEndpointSubnet.name
output privateEndpointSubnetId string = virtualNetwork::privateEndpointSubnet.id
