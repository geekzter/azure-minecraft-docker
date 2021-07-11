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
            "deepLink": "#@/resource${resource_group_id}/providers/Microsoft.ContainerInstance/containerGroups/${resource_group}-primary/overview",
            "inputs": [
              {
                "isOptional": true,
                "name": "id",
                "value": "${resource_group_id}/providers/Microsoft.ContainerInstance/containerGroups/${resource_group}-primary"
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
            "x": 13,
            "y": 6
          }
        },
        "11": {
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
            "savedContainerState": {
              "assetName": "${resource_group}-loganalytics",
              "partTitle": "Connection Events"
            },
            "settings": {
              "content": {
                "GridColumnsWidth": {
                  "Instance": "92px",
                  "Message": "362px",
                  "MessageWithoutTimestamp": "362px",
                  "TimeGenerated": "138px"
                },
                "PartSubTitle": "${resource_group}-loganalytics",
                "PartTitle": "Connection Events",
                "Query": "ContainerInstanceLog_CL \n| where Message contains \"connect\" or Message contains \"[/\" \n| extend MessageWithoutTimestamp=replace(@'\\[[^\\]]* (\\w+)\\]: ', @'[\\1] ', Message)\n| extend Instance=tostring(split(ContainerGroup_s,'-')[-1])\n| order by TimeGenerated desc\n| project TimeGenerated, Instance, Message=tolower(MessageWithoutTimestamp)\n"
              }
            },
            "type": "Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart"
          },
          "position": {
            "colSpan": 7,
            "metadata": null,
            "rowSpan": 6,
            "x": 0,
            "y": 10
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
            "savedContainerState": {
              "assetName": "${resource_group}",
              "partTitle": "Resources"
            },
            "type": "Extension/HubsExtension/PartType/ResourceGroupMapPinnedPart"
          },
          "position": {
            "colSpan": 6,
            "metadata": null,
            "rowSpan": 6,
            "x": 7,
            "y": 10
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
            "savedContainerState": {
              "assetName": "",
              "partTitle": " "
            },
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
            "x": 7,
            "y": 0
          }
        },
        "5": {
          "metadata": {
            "inputs": [
              {
                "isOptional": true,
                "name": "partTitle",
                "value": "Minecraft Instances"
              },
              {
                "isOptional": true,
                "name": "query",
                "value": "Resources\n| extend Repository=tostring(tags['repository']), Instance=tostring(tags['configuration-name']), VanityFQDN=tostring(tags['vanity-fqdn']), Workspace=tostring(tags['workspace']), Suffix=tostring(tags['suffix']) \n| where Repository == \"azure-minecraft-docker\" and isnotempty(Instance)\n| distinct Workspace, Instance, VanityFQDN\n| order by Workspace, Instance asc, VanityFQDN asc"
              },
              {
                "isOptional": true,
                "name": "chartType"
              },
              {
                "isOptional": true,
                "name": "isShared"
              },
              {
                "isOptional": true,
                "name": "queryId",
                "value": ""
              },
              {
                "isOptional": true,
                "name": "formatResults"
              }
            ],
            "savedContainerState": {
              "assetName": "Private Resource Graph query",
              "partTitle": "Minecraft Instances"
            },
            "settings": {},
            "type": "Extension/HubsExtension/PartType/ArgQueryGridTile"
          },
          "position": {
            "colSpan": 6,
            "metadata": null,
            "rowSpan": 6,
            "x": 13,
            "y": 0
          }
        },
        "6": {
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
                "name": "PartId",
                "value": "124593ba-0d3b-472c-b48a-eb7d2064245b"
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
                "value": "ContainerInstanceLog_CL \n| where Message contains \"connect\" or Message contains \"[/\" \n| extend Player=extract(@'\\]: *(\\w+)',1, Message)\n| summarize JoinTime=maxif(TimeGenerated,Message contains \"logged in with entity\"), LeaveTime=maxif(TimeGenerated,Message contains \"lost connection: \") by Player\n| where JoinTime > LeaveTime\n| order by JoinTime asc\n| project Player//, JoinTime\n"
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
                "name": "Dimensions"
              },
              {
                "isOptional": true,
                "name": "LegendOptions"
              },
              {
                "isOptional": true,
                "name": "IsQueryContainTimeRange",
                "value": false
              }
            ],
            "savedContainerState": {
              "assetName": "${resource_group}-loganalytics",
              "partTitle": "Player Status"
            },
            "settings": {
              "content": {
                "GridColumnsWidth": {
                  "Instance": "92px",
                  "Player": "126px",
                  "Status": "236px",
                  "TimeGenerated": "138px"
                },
                "PartTitle": "Player Status",
                "Query": "ContainerInstanceLog_CL \n| where Message contains \"lost connection: \" or Message contains \"logged in with entity\" \n| extend MessageWithoutTimestamp=replace(@'\\[[^\\]]* (\\w+)\\]: ', @'[\\1] ', Message)\n| extend OnlinePlayer=extract(@'\\]: *(\\w+)', 1, Message)\n| extend User=extract(@'name=(\\w+)', 1, Message)\n| extend Player=coalesce(User, OnlinePlayer)\n| extend DisconnectedStatus=extract(@'lost connection: *(.*)', 1, Message)\n| extend Status=coalesce(DisconnectedStatus, \"Joined\")\n| extend Instance=tostring(split(ContainerGroup_s,'-')[-1])\n| order by TimeGenerated desc\n| summarize arg_max(TimeGenerated, *) by Player, Instance\n| order by TimeGenerated desc\n| project TimeGenerated, Instance, Player, Status\n\n"
              }
            },
            "type": "Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart"
          },
          "position": {
            "colSpan": 7,
            "metadata": null,
            "rowSpan": 5,
            "x": 0,
            "y": 1
          }
        },
        "7": {
          "metadata": {
            "inputs": [],
            "savedContainerState": {
              "assetName": "Powered by Docker & Azure Container Instance",
              "partTitle": "Minecraft Server(less)"
            },
            "settings": {
              "content": {
                "settings": {
                  "content": "Minecraft Server running on <img width='10' src='https://portal.azure.com/favicon.ico'/>&nbsp;<a href='https://azure.microsoft.com/en-us/services/container-instances/' target='_blank'>Container&nbsp;Instance</a> and <img width='10' src='https://portal.azure.com/favicon.ico'/> <a href='https://azure.microsoft.com/en-us/services/storage/files/' target='_blank'>File Shares</a>. \n<br/>\nThe technology stack is all on GitHub:\n<ul>\n<li><a href='https://github.com/PaperMC' target='_blank'>Paper Minecraft</a>\n<li>Minecraft Docker image: <a href='https://github.com/itzg/docker-minecraft-server' target='_blank'>itzg/docker-minecraft-server</a>\n<li>How to provision this infrastructure:<a href='https://github.com/geekzter/azure-minecraft-docker' target='_blank'>\ngeekzter/azure-minecraft-docker </a>\n<li><a href='https://github.com/Azure/azure-cli' target='_blank'>Azure CLI</a>\n<li><a href='https://github.com/codespaces' target='_blank'>Codespace</a> (<a href='https://github.com/geekzter/azure-minecraft-docker/tree/main/.devcontainer' target='_blank'>definition</a>, <a href='https://github.com/features/codespaces' target='_blank'>\nfeature description</a>)\n<li>GitHub Actions <a href='https://github.com/geekzter/azure-minecraft-docker/actions?query=workflow%3Aci-vanilla' target='_blank'>CI workflow</a> (<a href='https://github.com/geekzter/azure-minecraft-docker/tree/main/.github/workflows' target='_blank'>source</a>)\n<li><a href='https://github.com/PowerShell/PowerShell' target='_blank'>Powershell</a>\n<li><a href='https://github.com/hashicorp/terraform' target='_blank'>Terraform (<a href='https://github.com/terraform-providers/terraform-provider-azuread' target='_blank'>azuread</a>,<a href='https://github.com/terraform-providers/terraform-provider-azurerm' target='_blank'>azurerm</a> providers)</a>\n</ul>",
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
            "x": 7,
            "y": 2
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
            "savedContainerState": {
              "assetName": "${resource_group}-loganalytics",
              "partTitle": "Container Events"
            },
            "settings": {
              "content": {
                "GridColumnsWidth": {
                  "Instance": "92px",
                  "Message": "362px",
                  "TimeGenerated": "138px"
                },
                "PartSubTitle": "${resource_group}-loganalytics",
                "PartTitle": "Container Events",
                "Query": "ContainerEvent_CL \n| extend Instance=tostring(split(ContainerGroup_s,'-')[-1])\n| project TimeGenerated, Instance, Message\n| order by TimeGenerated desc"
              }
            },
            "type": "Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart"
          },
          "position": {
            "colSpan": 7,
            "metadata": null,
            "rowSpan": 4,
            "x": 0,
            "y": 6
          }
        },
        "9": {
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
            "savedContainerState": {
              "assetName": "Resources tagged 'repository'='azure-minecraft-docker'",
              "partTitle": "Cost Consumption"
            },
            "type": "Extension/Microsoft_Azure_CostManagement/PartType/CostAnalysisPinPart"
          },
          "position": {
            "colSpan": 6,
            "metadata": null,
            "rowSpan": 4,
            "x": 7,
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
              "StartboardPart-LogsDashboardPart-509a799a-9431-48a7-9ab1-9bd1561f4013",
              "StartboardPart-LogsDashboardPart-509a799a-9431-48a7-9ab1-9bd1561f4017",
              "StartboardPart-MonitorChartPart-509a799a-9431-48a7-9ab1-9bd1561f401b",
              "StartboardPart-LogsDashboardPart-509a799a-9431-48a7-9ab1-9bd1561f401d"
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
    "provisoner-email": "ericvan@microsoft.com",
    "repository": "azure-minecraft-docker",
    "runid": "",
    "suffix": "${suffix}",
    "workspace": "${workspace}"
  },
  "type": "Microsoft.Portal/dashboards"
}
