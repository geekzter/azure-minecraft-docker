{
  "id": "${resource_group_id}/providers/Microsoft.Portal/dashboards/Minecraft-${workspace}-${suffix}-dashboard",
  "lenses": {
    "0": {
      "metadata": null,
      "order": 0,
      "parts": {
        "0": {
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
            "x": 0,
            "y": 0
          }
        },
        "1": {
          "metadata": {
            "inputs": [
              {
                "name": "budgetId",
                "value": "subscriptions/${subscription_guid}/providers/Microsoft.Consumption/budgets/MinecraftBudget"
              }
            ],
            "type": "Extension/Microsoft_Azure_CostManagement/PartType/CurrentSpendvsBudgetPart"
          },
          "position": {
            "colSpan": 4,
            "metadata": null,
            "rowSpan": 2,
            "x": 2,
            "y": 0
          }
        },
        "2": {
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
                          "resourceGroup": "Minecraft-${workspace}-${suffix}"
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
                          "resourceGroup": "Minecraft-${workspace}-${suffix}"
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
            "x": 6,
            "y": 0
          }
        },
        "3": {
          "metadata": {
            "deepLink": "#blade/Microsoft_Azure_CostManagement/Menu/costanalysis",
            "inputs": [
              {
                "name": "scope",
                "value": "/subscriptions/${subscription_guid}"
              },
              {
                "name": "scopeName",
                "value": "Microsoft Internal - Eric van Wijk"
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
            "y": 4
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
                          "displayName": "Memory Usage",
                          "resourceDisplayName": "minecraft-${suffix}"
                        },
                        "name": "MemoryUsage",
                        "resourceMetadata": {
                          "id": "${resource_group_id}/providers/Microsoft.ContainerInstance/containerGroups/Minecraft-${suffix}",
                          "resourceGroup": "Minecraft-${workspace}-${suffix}"
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
                          "resourceGroup": "Minecraft-${workspace}-${suffix}"
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
            "x": 6,
            "y": 4
          }
        },
        "5": {
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
                          "resourceGroup": "Minecraft-${workspace}-${suffix}"
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
                          "resourceGroup": "Minecraft-${workspace}-${suffix}"
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
            "x": 6,
            "y": 8
          }
        }
      }
    }
  },
  "location": "westeurope",
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
              "StartboardPart-MonitorChartPart-f5bcd0d9-d6f1-43b3-a734-44460109a63d",
              "StartboardPart-MonitorChartPart-f5bcd0d9-d6f1-43b3-a734-44460109a63f",
              "StartboardPart-MonitorChartPart-f5bcd0d9-d6f1-43b3-a734-44460109a641"
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
  "name": "Minecraft-${workspace}-${suffix}-dashboard",
  "resourceGroup": "Minecraft-${workspace}-${suffix}",
  "tags": {
    "application": "Minecraft",
    "environment": "dev",
    "hidden-title": "Minecraft (dev)",
    "provisioner": "terraform",
    "repository": "azure-minecraft-docker",
    "suffix": "${suffix}",
    "workspace": "${workspace}"
  },
  "type": "Microsoft.Portal/dashboards"
}
