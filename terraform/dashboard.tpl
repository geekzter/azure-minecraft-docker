{
  "id": "${resource_group_id}/providers/Microsoft.Portal/dashboards/${resource_group}-dashboard",
  "lenses": {
    "0": {
      "metadata": null,
      "order": 0,
      "parts": {
        "0": {
          "metadata": {
            "asset": {
              "idInputName": "id"
            },
            "deepLink": "#@/resource${resource_group_id}/providers/Microsoft.ContainerInstance/containerGroups/Minecraft-${suffix}/overview",
            "inputs": [
              {
                "isOptional": true,
                "name": "id",
                "value": "${resource_group_id}/providers/Microsoft.ContainerInstance/containerGroups/Minecraft-${suffix}"
              },
              {
                "isOptional": true,
                "name": "resourceId"
              },
              {
                "isOptional": true,
                "name": "menuid"
              }
            ],
            "type": "Extension/HubsExtension/PartType/ResourcePart"
          },
          "position": {
            "colSpan": 2,
            "metadata": null,
            "rowSpan": 1,
            "x": 0,
            "y": 0
          }
        },
        "1": {
          "metadata": {
            "asset": {
              "idInputName": "id",
              "type": "Workspace"
            },
            "deepLink": "#@/resource${resource_group_id}/providers/Microsoft.OperationalInsights/workspaces/${resource_group}-loganalytics/Overview",
            "inputs": [
              {
                "name": "id",
                "value": "${resource_group_id}/providers/microsoft.operationalinsights/workspaces/${resource_group}-loganalytics"
              }
            ],
            "type": "Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/WorkspacePart"
          },
          "position": {
            "colSpan": 2,
            "metadata": null,
            "rowSpan": 1,
            "x": 2,
            "y": 0
          }
        },
        "10": {
          "metadata": {
            "deepLink": "#@/resource${resource_group_id}/overview",
            "inputs": [
              {
                "isOptional": true,
                "name": "resourceGroup"
              },
              {
                "isOptional": true,
                "name": "id",
                "value": "${resource_group_id}"
              }
            ],
            "type": "Extension/HubsExtension/PartType/ResourceGroupMapPinnedPart"
          },
          "position": {
            "colSpan": 6,
            "metadata": null,
            "rowSpan": 3,
            "x": 0,
            "y": 9
          }
        },
        "11": {
          "metadata": {
            "filters": {
              "MsPortalFx_TimeRange": {
                "model": {
                  "format": "local",
                  "granularity": "auto",
                  "relative": "1440m"
                }
              }
            },
            "inputs": [
              {
                "isOptional": true,
                "name": "options",
                "value": {
                  "chart": {
                    "metrics": [
                      {
                        "aggregationType": 4,
                        "metricVisualization": {
                          "displayName": "Used capacity"
                        },
                        "name": "UsedCapacity",
                        "namespace": "microsoft.storage/storageaccounts",
                        "resourceMetadata": {
                          "id": "${resource_group_id}/providers/Microsoft.Storage/storageAccounts/minecraftstor${suffix}",
                          "resourceGroup": "${resource_group}"
                        }
                      }
                    ],
                    "timespan": {
                      "grain": 1,
                      "relative": {
                        "duration": 86400000
                      },
                      "showUTCTime": false
                    },
                    "title": "Avg Used capacity for minecraftstor${suffix}",
                    "titleKind": 1,
                    "visualization": {
                      "axisVisualization": {
                        "x": {
                          "axisType": 2,
                          "isVisible": true
                        },
                        "y": {
                          "axisType": 1,
                          "isVisible": true
                        }
                      },
                      "chartType": 2,
                      "legendVisualization": {
                        "hideSubtitle": false,
                        "isVisible": true,
                        "position": 2
                      }
                    }
                  }
                }
              },
              {
                "isOptional": true,
                "name": "sharedTimeRange"
              }
            ],
            "settings": {
              "content": {
                "options": {
                  "chart": {
                    "metrics": [
                      {
                        "aggregationType": 4,
                        "metricVisualization": {
                          "displayName": "Used capacity"
                        },
                        "name": "UsedCapacity",
                        "namespace": "microsoft.storage/storageaccounts",
                        "resourceMetadata": {
                          "id": "${resource_group_id}/providers/Microsoft.Storage/storageAccounts/minecraftstor${suffix}",
                          "resourceGroup": "${resource_group}"
                        }
                      }
                    ],
                    "title": "Avg Used capacity for minecraftstor${suffix}",
                    "titleKind": 1,
                    "visualization": {
                      "axisVisualization": {
                        "x": {
                          "axisType": 2,
                          "isVisible": true
                        },
                        "y": {
                          "axisType": 1,
                          "isVisible": true
                        }
                      },
                      "chartType": 2,
                      "disablePinning": true,
                      "legendVisualization": {
                        "hideSubtitle": false,
                        "isVisible": true,
                        "position": 2
                      }
                    }
                  }
                }
              }
            },
            "type": "Extension/HubsExtension/PartType/MonitorChartPart"
          },
          "position": {
            "colSpan": 6,
            "metadata": null,
            "rowSpan": 4,
            "x": 12,
            "y": 12
          }
        },
        "2": {
          "metadata": {
            "deepLink": "#@/resource${resource_group_id}/providers/Microsoft.Storage/storageAccounts/minecraftstor${suffix}/fileList",
            "inputs": [
              {
                "name": "storageAccountId",
                "value": "${resource_group_id}/providers/Microsoft.Storage/storageAccounts/minecraftstor${suffix}"
              }
            ],
            "type": "Extension/Microsoft_Azure_FileStorage/PartType/FileServicePinnedPart"
          },
          "position": {
            "colSpan": 2,
            "metadata": null,
            "rowSpan": 1,
            "x": 4,
            "y": 0
          }
        },
        "3": {
          "metadata": {
            "inputs": [
              {
                "isOptional": true,
                "name": "ComponentId",
                "value": {
                  "Name": "${resource_group}-loganalytics",
                  "ResourceGroup": "${resource_group}",
                  "ResourceId": "${resource_group_id}/providers/microsoft.operationalinsights/workspaces/${resource_group}-loganalytics",
                  "SubscriptionId": "${subscription_guid}"
                }
              },
              {
                "isOptional": true,
                "name": "Dimensions"
              },
              {
                "isOptional": true,
                "name": "PartId",
                "value": "11a37614-4dbc-4fe6-a814-91aee9a148a9"
              },
              {
                "isOptional": true,
                "name": "Version",
                "value": "1.0"
              },
              {
                "isOptional": true,
                "name": "resourceTypeMode",
                "value": "workspace"
              },
              {
                "isOptional": true,
                "name": "TimeRange",
                "value": "P1D"
              },
              {
                "isOptional": true,
                "name": "DashboardId"
              },
              {
                "isOptional": true,
                "name": "DraftRequestParameters"
              },
              {
                "isOptional": true,
                "name": "Query",
                "value": "ContainerEvent_CL \n| project TimeGenerated, Message\n| order by TimeGenerated desc\n"
              },
              {
                "isOptional": true,
                "name": "ControlType",
                "value": "AnalyticsGrid"
              },
              {
                "isOptional": true,
                "name": "SpecificChart"
              },
              {
                "isOptional": true,
                "name": "PartTitle",
                "value": "Analytics"
              },
              {
                "isOptional": true,
                "name": "PartSubTitle",
                "value": "${resource_group}-loganalytics"
              }
            ],
            "settings": {
              "content": {
                "GridColumnsWidth": {
                  "Message": "362px"
                },
                "PartSubTitle": "${resource_group}-loganalytics",
                "PartTitle": "Events"
              }
            },
            "type": "Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart"
          },
          "position": {
            "colSpan": 6,
            "metadata": null,
            "rowSpan": 5,
            "x": 6,
            "y": 0
          }
        },
        "4": {
          "metadata": {
            "filters": {
              "MsPortalFx_TimeRange": {
                "model": {
                  "format": "local",
                  "granularity": "auto",
                  "relative": "60m"
                }
              }
            },
            "inputs": [
              {
                "isOptional": true,
                "name": "options",
                "value": {
                  "chart": {
                    "metrics": [
                      {
                        "aggregationType": 4,
                        "metricVisualization": {
                          "displayName": "CPU Usage",
                          "resourceDisplayName": "minecraft-${suffix}"
                        },
                        "name": "CpuUsage",
                        "resourceMetadata": {
                          "id": "${resource_group_id}/providers/Microsoft.ContainerInstance/containerGroups/Minecraft-${suffix}",
                          "resourceGroup": "${resource_group}"
                        }
                      }
                    ],
                    "openBladeOnClick": {
                      "openBlade": true
                    },
                    "title": "CPU",
                    "titleKind": 2,
                    "visualization": {
                      "chartType": 2
                    }
                  }
                }
              },
              {
                "isOptional": true,
                "name": "sharedTimeRange"
              }
            ],
            "settings": {
              "content": {
                "options": {
                  "chart": {
                    "metrics": [
                      {
                        "aggregationType": 4,
                        "metricVisualization": {
                          "displayName": "CPU Usage",
                          "resourceDisplayName": "minecraft-${suffix}"
                        },
                        "name": "CpuUsage",
                        "resourceMetadata": {
                          "id": "${resource_group_id}/providers/Microsoft.ContainerInstance/containerGroups/Minecraft-${suffix}",
                          "resourceGroup": "${resource_group}"
                        }
                      }
                    ],
                    "openBladeOnClick": {
                      "openBlade": true
                    },
                    "title": "CPU",
                    "titleKind": 2,
                    "visualization": {
                      "chartType": 2,
                      "disablePinning": true
                    }
                  }
                }
              }
            },
            "type": "Extension/HubsExtension/PartType/MonitorChartPart"
          },
          "position": {
            "colSpan": 6,
            "metadata": null,
            "rowSpan": 4,
            "x": 12,
            "y": 0
          }
        },
        "5": {
          "metadata": {
            "inputs": [],
            "settings": {
              "content": {
                "settings": {
                  "content": "Minecraft Server running at <a href='minecraft://${minecraft_server_fqdn}' target='_blank'>${minecraft_server_fqdn}</a> on <img width='10' src='https://portal.azure.com/favicon.ico'/>&nbsp;<a href='https://azure.microsoft.com/en-us/services/container-instances/' target='_blank'>Container&nbsp;Instance</a> and <img width='10' src='https://portal.azure.com/favicon.ico'/> <a href='https://azure.microsoft.com/en-us/services/storage/files/' target='_blank'>File Shares</a>\n\nThe technology stack is all on GitHub:\n<ul>\n<li><a href='https://github.com/PaperMC' target='_blank'>Paper Minecraft</a>\n<li>Minecraft Docker image: <a href='https://github.com/itzg/docker-minecraft-server' target='_blank'>itzg/docker-minecraft-server</a>\n<li>Repo that deployed this infrastructure:<a href='https://github.com/geekzter/azure-minecraft-docker' target='_blank'>\ngeekzter/azure-minecraft-docker </a>\n<li>GitHub Actions <a href='https://github.com/geekzter/azure-minecraft-docker/actions?query=workflow%3Aci-vanilla' target='_blank'>\nCI</a> (<a href='https://github.com/geekzter/azure-minecraft-docker/tree/main/.github/workflows' target='_blank'>source</a>)\n<li><a href='https://github.com/features/codespaces' target='_blank'>\nCodespace</a> (<a href='https://github.com/geekzter/azure-minecraft-docker/tree/main/.devcontainer' target='_blank'>definition</a>)\n<li><a href='https://github.com/PowerShell/PowerShell' target='_blank'>Powershell</a>\n<li><a href='https://github.com/hashicorp/terraform' target='_blank'>Terraform</a>\n<li>Terraform <a href='https://github.com/terraform-providers/terraform-provider-azurerm' target='_blank'>azurerm provider</a>\n<li><a href='https://github.com/Azure/azure-cli' target='_blank'>Azure CLI</a>\n</ul>",
                  "markdownSource": 1,
                  "subtitle": "Powered by Docker & Azure Container Instance",
                  "title": "Minecraft Server "
                }
              }
            },
            "type": "Extension/HubsExtension/PartType/MarkdownPart"
          },
          "position": {
            "colSpan": 6,
            "metadata": null,
            "rowSpan": 4,
            "x": 0,
            "y": 1
          }
        },
        "6": {
          "metadata": {
            "filters": {
              "MsPortalFx_TimeRange": {
                "model": {
                  "format": "local",
                  "granularity": "auto",
                  "relative": "60m"
                }
              }
            },
            "inputs": [
              {
                "isOptional": true,
                "name": "options",
                "value": {
                  "chart": {
                    "metrics": [
                      {
                        "aggregationType": 4,
                        "metricVisualization": {
                          "displayName": "Memory Usage",
                          "resourceDisplayName": "minecraft-${suffix}"
                        },
                        "name": "MemoryUsage",
                        "resourceMetadata": {
                          "id": "${resource_group_id}/providers/Microsoft.ContainerInstance/containerGroups/Minecraft-${suffix}",
                          "resourceGroup": "${resource_group}"
                        }
                      }
                    ],
                    "openBladeOnClick": {
                      "openBlade": true
                    },
                    "title": "Memory",
                    "titleKind": 2,
                    "visualization": {
                      "chartType": 2
                    }
                  }
                }
              },
              {
                "isOptional": true,
                "name": "sharedTimeRange"
              }
            ],
            "settings": {
              "content": {
                "options": {
                  "chart": {
                    "metrics": [
                      {
                        "aggregationType": 4,
                        "metricVisualization": {
                          "displayName": "Memory Usage",
                          "resourceDisplayName": "minecraft-${suffix}"
                        },
                        "name": "MemoryUsage",
                        "resourceMetadata": {
                          "id": "${resource_group_id}/providers/Microsoft.ContainerInstance/containerGroups/Minecraft-${suffix}",
                          "resourceGroup": "${resource_group}"
                        }
                      }
                    ],
                    "openBladeOnClick": {
                      "openBlade": true
                    },
                    "title": "Memory",
                    "titleKind": 2,
                    "visualization": {
                      "chartType": 2,
                      "disablePinning": true
                    }
                  }
                }
              }
            },
            "type": "Extension/HubsExtension/PartType/MonitorChartPart"
          },
          "position": {
            "colSpan": 6,
            "metadata": null,
            "rowSpan": 4,
            "x": 12,
            "y": 4
          }
        },
        "7": {
          "metadata": {
            "deepLink": "#blade/Microsoft_Azure_CostManagement/Menu/costanalysis",
            "inputs": [
              {
                "name": "scope",
                "value": "/subscriptions/${subscription_guid}"
              },
              {
                "name": "scopeName",
                "value": "${subscription_guid}"
              },
              {
                "isOptional": true,
                "name": "view",
                "value": {
                  "accumulated": "true",
                  "chart": "Area",
                  "currency": "USD",
                  "dateRange": "ThisMonth",
                  "displayName": "Minecraft Server",
                  "kpis": [
                    {
                      "enabled": true,
                      "extendedProperties": {
                        "amount": 2500,
                        "name": "NormalBudget",
                        "timeGrain": "Monthly",
                        "type": "${subscription_guid}"
                      },
                      "id": "${subscription_id}/providers/Microsoft.Consumption/budgets/NormalBudget",
                      "type": "Budget"
                    },
                    {
                      "enabled": true,
                      "type": "Forecast"
                    }
                  ],
                  "pivots": [
                    {
                      "name": "ServiceName",
                      "type": "Dimension"
                    },
                    {
                      "name": "ResourceLocation",
                      "type": "Dimension"
                    },
                    {
                      "name": "ResourceGroupName",
                      "type": "Dimension"
                    }
                  ],
                  "query": {
                    "dataSet": {
                      "aggregation": {
                        "totalCost": {
                          "function": "Sum",
                          "name": "Cost"
                        },
                        "totalCostUSD": {
                          "function": "Sum",
                          "name": "CostUSD"
                        }
                      },
                      "filter": {
                        "Tags": {
                          "Name": "repository",
                          "Operator": "In",
                          "Values": [
                            "azure-minecraft-docker"
                          ]
                        }
                      },
                      "granularity": "Daily",
                      "sorting": [
                        {
                          "direction": "ascending",
                          "name": "UsageDate"
                        }
                      ]
                    },
                    "timeframe": "None",
                    "type": "ActualCost"
                  },
                  "scope": "subscriptions/${subscription_guid}"
                }
              },
              {
                "isOptional": true,
                "name": "externalState"
              }
            ],
            "type": "Extension/Microsoft_Azure_CostManagement/PartType/CostAnalysisPinPart"
          },
          "position": {
            "colSpan": 6,
            "metadata": null,
            "rowSpan": 4,
            "x": 0,
            "y": 5
          }
        },
        "8": {
          "metadata": {
            "inputs": [
              {
                "isOptional": true,
                "name": "ComponentId",
                "value": {
                  "Name": "${resource_group}-loganalytics",
                  "ResourceGroup": "${resource_group}",
                  "ResourceId": "${resource_group_id}/providers/microsoft.operationalinsights/workspaces/${resource_group}-loganalytics",
                  "SubscriptionId": "${subscription_guid}"
                }
              },
              {
                "isOptional": true,
                "name": "Dimensions"
              },
              {
                "isOptional": true,
                "name": "PartId",
                "value": "688a3af1-10e7-459c-a613-30a97b00a33d"
              },
              {
                "isOptional": true,
                "name": "Version",
                "value": "1.0"
              },
              {
                "isOptional": true,
                "name": "resourceTypeMode",
                "value": "workspace"
              },
              {
                "isOptional": true,
                "name": "TimeRange",
                "value": "P1D"
              },
              {
                "isOptional": true,
                "name": "DashboardId"
              },
              {
                "isOptional": true,
                "name": "DraftRequestParameters"
              },
              {
                "isOptional": true,
                "name": "Query",
                "value": "ContainerInstanceLog_CL \n| where Message contains \"connect\" or Message contains \"[/\" \n| project TimeGenerated, Message\n| order by TimeGenerated desc\n"
              },
              {
                "isOptional": true,
                "name": "ControlType",
                "value": "AnalyticsGrid"
              },
              {
                "isOptional": true,
                "name": "SpecificChart"
              },
              {
                "isOptional": true,
                "name": "PartTitle",
                "value": "Analytics"
              },
              {
                "isOptional": true,
                "name": "PartSubTitle",
                "value": "${resource_group}-loganalytics"
              }
            ],
            "settings": {
              "content": {
                "GridColumnsWidth": {
                  "Message": "359px"
                },
                "PartSubTitle": "${resource_group}-loganalytics",
                "PartTitle": "Connection Events"
              }
            },
            "type": "Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart"
          },
          "position": {
            "colSpan": 6,
            "metadata": null,
            "rowSpan": 7,
            "x": 6,
            "y": 5
          }
        },
        "9": {
          "metadata": {
            "filters": {
              "MsPortalFx_TimeRange": {
                "model": {
                  "format": "local",
                  "granularity": "auto",
                  "relative": "60m"
                }
              }
            },
            "inputs": [
              {
                "isOptional": true,
                "name": "options",
                "value": {
                  "chart": {
                    "metrics": [
                      {
                        "aggregationType": 4,
                        "metricVisualization": {
                          "displayName": "Network Bytes Transmitted Per Second",
                          "resourceDisplayName": "minecraft-${suffix}"
                        },
                        "name": "NetworkBytesTransmittedPerSecond",
                        "resourceMetadata": {
                          "id": "${resource_group_id}/providers/Microsoft.ContainerInstance/containerGroups/Minecraft-${suffix}",
                          "resourceGroup": "${resource_group}"
                        }
                      }
                    ],
                    "openBladeOnClick": {
                      "openBlade": true
                    },
                    "title": "Network bytes transmitted",
                    "titleKind": 2,
                    "visualization": {
                      "chartType": 2
                    }
                  }
                }
              },
              {
                "isOptional": true,
                "name": "sharedTimeRange"
              }
            ],
            "settings": {
              "content": {
                "options": {
                  "chart": {
                    "metrics": [
                      {
                        "aggregationType": 4,
                        "metricVisualization": {
                          "displayName": "Network Bytes Transmitted Per Second",
                          "resourceDisplayName": "minecraft-${suffix}"
                        },
                        "name": "NetworkBytesTransmittedPerSecond",
                        "resourceMetadata": {
                          "id": "${resource_group_id}/providers/Microsoft.ContainerInstance/containerGroups/Minecraft-${suffix}",
                          "resourceGroup": "${resource_group}"
                        }
                      }
                    ],
                    "openBladeOnClick": {
                      "openBlade": true
                    },
                    "title": "Network bytes transmitted",
                    "titleKind": 2,
                    "visualization": {
                      "chartType": 2,
                      "disablePinning": true
                    }
                  }
                }
              }
            },
            "type": "Extension/HubsExtension/PartType/MonitorChartPart"
          },
          "position": {
            "colSpan": 6,
            "metadata": null,
            "rowSpan": 4,
            "x": 12,
            "y": 8
          }
        }
      }
    }
  },
  "location": "${location}",
  "metadata": {
    "model": {
      "filterLocale": {
        "value": "en-us"
      },
      "filters": {
        "value": {
          "MsPortalFx_TimeRange": {
            "displayCache": {
              "name": "UTC Time",
              "value": "Past 24 hours"
            },
            "filteredPartIds": [
              "StartboardPart-LogsDashboardPart-42de4876-4f34-46a1-a933-f68c06cbb4b3",
              "StartboardPart-MonitorChartPart-42de4876-4f34-46a1-a933-f68c06cbb4b5",
              "StartboardPart-MonitorChartPart-42de4876-4f34-46a1-a933-f68c06cbb4b9",
              "StartboardPart-LogsDashboardPart-42de4876-4f34-46a1-a933-f68c06cbb4bd",
              "StartboardPart-MonitorChartPart-42de4876-4f34-46a1-a933-f68c06cbb4bf",
              "StartboardPart-MonitorChartPart-42de4876-4f34-46a1-a933-f68c06cbb4c3"
            ],
            "model": {
              "format": "utc",
              "granularity": "auto",
              "relative": "24h"
            }
          }
        }
      },
      "timeRange": {
        "type": "MsPortalFx.Composition.Configuration.ValueTypes.TimeRange",
        "value": {
          "relative": {
            "duration": 24,
            "timeUnit": 1
          }
        }
      }
    }
  },
  "name": "${resource_group}-dashboard",
  "resourceGroup": "${resource_group}",
  "tags": {
    "application": "Minecraft",
    "environment": "${environment}",
    "hidden-title": "Minecraft ({environment})",
    "provisioner": "terraform",
    "repository": "azure-minecraft-docker",
    "runid": "",
    "suffix": "${suffix}",
    "workspace": "${workspace}"
  },
  "type": "Microsoft.Portal/dashboards"
}
