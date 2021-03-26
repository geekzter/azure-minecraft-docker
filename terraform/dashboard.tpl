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
            "colSpan": 1,
            "metadata": null,
            "rowSpan": 1,
            "x": 2,
            "y": 0
          }
        },
        "10": {
          "metadata": {
            "deepLink": "#blade/Microsoft_Azure_CostManagement/Menu/costanalysis",
            "inputs": [
              {
                "name": "scope",
                "value": "/subscriptions/${subscription_guid}"
              },
              {
                "name": "scopeName",
                "value": "Resources tagged 'repository'='azure-minecraft-docker'"
              },
              {
                "isOptional": true,
                "name": "view",
                "value": {
                  "accumulated": "true",
                  "chart": "Area",
                  "currency": "USD",
                  "dateRange": "ThisMonth",
                  "displayName": "Cost Consumption",
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
            "x": 6,
            "y": 6
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
                        "namespace": "microsoft.containerinstance/containergroups",
                        "resourceMetadata": {
                          "id": "${resource_group_id}/providers/Microsoft.ContainerInstance/containerGroups/Minecraft-${suffix}",
                          "resourceGroup": "${resource_group}"
                        }
                      }
                    ],
                    "title": "Network bytes transmitted",
                    "titleKind": 2,
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
            "y": 8
          }
        },
        "12": {
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
            "rowSpan": 6,
            "x": 6,
            "y": 10
          }
        },
        "13": {
          "metadata": {
            "filters": {
              "MsPortalFx_TimeRange": {
                "model": {
                  "format": "local",
                  "granularity": "auto",
                  "relative": "43200m"
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
                          "displayName": "Used storage capacity"
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
                          "displayName": "Used storage capacity"
                        },
                        "name": "UsedCapacity",
                        "namespace": "microsoft.storage/storageaccounts",
                        "resourceMetadata": {
                          "id": "${resource_group_id}/providers/Microsoft.Storage/storageAccounts/minecraftstor${suffix}",
                          "resourceGroup": "${resource_group}"
                        }
                      }
                    ],
                    "title": "Used storage capacity",
                    "titleKind": 2,
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
            "inputs": [
              {
                "isOptional": true,
                "name": "queryInputs"
              }
            ],
            "type": "Extension/Microsoft_Azure_Monitoring/PartType/AlertsManagementSummaryBladePinnedPart"
          },
          "position": {
            "colSpan": 1,
            "metadata": null,
            "rowSpan": 1,
            "x": 3,
            "y": 0
          }
        },
        "3": {
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
            "x": 4,
            "y": 0
          }
        },
        "4": {
          "metadata": {
            "inputs": [],
            "settings": {
              "content": {
                "settings": {
                  "content": "<img src='https://github.com/geekzter/azure-minecraft-docker/raw/main/visuals/minecraft-logo-800.png' align='middle'/>\n",
                  "markdownSource": 1,
                  "markdownUri": "https://logos-world.net/wp-content/uploads/2020/04/Minecraft-Logo.png",
                  "subtitle": "",
                  "title": " "
                }
              }
            },
            "type": "Extension/HubsExtension/PartType/MarkdownPart"
          },
          "position": {
            "colSpan": 6,
            "metadata": null,
            "rowSpan": 2,
            "x": 6,
            "y": 0
          }
        },
        "5": {
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
                        "namespace": "microsoft.containerinstance/containergroups",
                        "resourceMetadata": {
                          "id": "${resource_group_id}/providers/Microsoft.ContainerInstance/containerGroups/Minecraft-${suffix}",
                          "resourceGroup": "${resource_group}"
                        }
                      }
                    ],
                    "title": "CPU (millicores)",
                    "titleKind": 2,
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
            "y": 0
          }
        },
        "6": {
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
              },
              {
                "isOptional": true,
                "name": "Scope"
              },
              {
                "isOptional": true,
                "name": "LegendOptions"
              },
              {
                "isOptional": true,
                "name": "IsQueryContainTimeRange"
              }
            ],
            "settings": {
              "content": {
                "GridColumnsWidth": {
                  "Message": "362px",
                  "TimeGenerated": "138px"
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
            "x": 0,
            "y": 1
          }
        },
        "7": {
          "metadata": {
            "inputs": [],
            "settings": {
              "content": {
                "settings": {
                  "content": "Minecraft Server running at <a href='minecraft://${minecraft_server_fqdn}' target='_blank'>${minecraft_server_fqdn}</a> on <img width='10' src='https://portal.azure.com/favicon.ico'/>&nbsp;<a href='https://azure.microsoft.com/en-us/services/container-instances/' target='_blank'>Container&nbsp;Instance</a> and <img width='10' src='https://portal.azure.com/favicon.ico'/> <a href='https://azure.microsoft.com/en-us/services/storage/files/' target='_blank'>File Shares</a>. \n<br/>\nThe technology stack is all on GitHub:\n<ul>\n<li><a href='https://github.com/PaperMC' target='_blank'>Paper Minecraft</a>\n<li>Minecraft Docker image: <a href='https://github.com/itzg/docker-minecraft-server' target='_blank'>itzg/docker-minecraft-server</a>\n<li>How to provision this infrastructure:<a href='https://github.com/geekzter/azure-minecraft-docker' target='_blank'>\ngeekzter/azure-minecraft-docker </a>\n<li><a href='https://github.com/Azure/azure-cli' target='_blank'>Azure CLI</a>\n<li><a href='https://github.com/codespaces' target='_blank'>Codespace</a> (<a href='https://github.com/geekzter/azure-minecraft-docker/tree/main/.devcontainer' target='_blank'>definition</a>, <a href='https://github.com/features/codespaces' target='_blank'>\nfeature description</a>)\n<li>GitHub Actions <a href='https://github.com/geekzter/azure-minecraft-docker/actions?query=workflow%3Aci-vanilla' target='_blank'>CI workflow</a> (<a href='https://github.com/geekzter/azure-minecraft-docker/tree/main/.github/workflows' target='_blank'>source</a>)\n<li><a href='https://github.com/PowerShell/PowerShell' target='_blank'>Powershell</a>\n<li><a href='https://github.com/hashicorp/terraform' target='_blank'>Terraform (<a href='https://github.com/terraform-providers/terraform-provider-azuread' target='_blank'>azuread</a>,<a href='https://github.com/terraform-providers/terraform-provider-azurerm' target='_blank'>azurerm</a> providers)</a>\n</ul>",
                  "markdownSource": 1,
                  "subtitle": "Powered by Docker & Azure Container Instance",
                  "title": "Minecraft Server(less)"
                }
              }
            },
            "type": "Extension/HubsExtension/PartType/MarkdownPart"
          },
          "position": {
            "colSpan": 6,
            "metadata": null,
            "rowSpan": 4,
            "x": 6,
            "y": 2
          }
        },
        "8": {
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
                        "namespace": "microsoft.containerinstance/containergroups",
                        "resourceMetadata": {
                          "id": "${resource_group_id}/providers/Microsoft.ContainerInstance/containerGroups/Minecraft-${suffix}",
                          "resourceGroup": "${resource_group}"
                        }
                      }
                    ],
                    "title": "Memory",
                    "titleKind": 2,
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
            "y": 4
          }
        },
        "9": {
          "metadata": {
            "inputs": [
              {
                "isOptional": true,
                "name": "resourceTypeMode"
              },
              {
                "isOptional": true,
                "name": "ComponentId"
              },
              {
                "isOptional": true,
                "name": "Scope",
                "value": {
                  "resourceIds": [
                    "${resource_group_id}/providers/microsoft.operationalinsights/workspaces/${resource_group}-loganalytics"
                  ]
                }
              },
              {
                "isOptional": true,
                "name": "Dimensions"
              },
              {
                "isOptional": true,
                "name": "PartId",
                "value": "15a53e10-286d-4b38-ac93-bd98b26c8546"
              },
              {
                "isOptional": true,
                "name": "Version",
                "value": "2.0"
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
                "value": "ContainerInstanceLog_CL \n| where Message contains \"connect\" or Message contains \"[/\" \n| order by TimeGenerated desc\n| project Message\n\n"
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
              },
              {
                "isOptional": true,
                "name": "LegendOptions"
              },
              {
                "isOptional": true,
                "name": "IsQueryContainTimeRange"
              }
            ],
            "settings": {
              "content": {
                "GridColumnsWidth": {
                  "Message": "362px",
                  "MessageWithoutTimestamp": "362px",
                  "TimeGenerated": "138px"
                },
                "PartSubTitle": "${resource_group}-loganalytics",
                "PartTitle": "Connection Events",
                "Query": "ContainerInstanceLog_CL \n| where Message contains \"connect\" or Message contains \"[/\" \n| extend MessageWithoutTimestamp=replace(@'\\[[^\\]]* (\\w+)\\]: ', @'[\\1] ', Message)\n| order by TimeGenerated desc\n| project TimeGenerated, Message=tolower(MessageWithoutTimestamp)"
              }
            },
            "type": "Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart"
          },
          "position": {
            "colSpan": 6,
            "metadata": null,
            "rowSpan": 10,
            "x": 0,
            "y": 6
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
              "name": "Local Time",
              "value": "Past 30 days"
            },
            "filteredPartIds": [
              "StartboardPart-MonitorChartPart-9281c0f9-8170-4507-8176-a2d28dbe361d",
              "StartboardPart-MonitorChartPart-9281c0f9-8170-4507-8176-a2d28dbe3621",
              "StartboardPart-MonitorChartPart-9281c0f9-8170-4507-8176-a2d28dbe3627",
              "StartboardPart-LogsDashboardPart-9281c0f9-8170-4507-8176-a2d28dbe3629",
              "StartboardPart-MonitorChartPart-9281c0f9-8170-4507-8176-a2d28dbe362d",
              "StartboardPart-LogsDashboardPart-9281c0f9-8170-4507-8176-a2d28dbe362f"
            ],
            "model": {
              "format": "local",
              "granularity": "auto",
              "relative": "43200m"
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
    "environment": "${workspace}",
    "hidden-title": "Minecraft ({environment})",
    "provisioner": "terraform",
    "repository": "azure-minecraft-docker",
    "runid": "",
    "suffix": "${suffix}",
    "workspace": "${workspace}"
  },
  "type": "Microsoft.Portal/dashboards"
}
