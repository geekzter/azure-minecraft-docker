using System;
using System.Collections.Generic;
using System.Diagnostics;
using Microsoft.ApplicationInsights;
using Microsoft.ApplicationInsights.DataContracts;
using Microsoft.ApplicationInsights.Extensibility;
using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Logging;
using System.Net.Sockets;
using System.Threading;

namespace EW.Minecraft.Function
{
    public class PingTest
    {
        private const string TimerFormat = @"hh\:mm\:ss";
        private const string MinecraftFqdnVariable = "MINECRAFT_FQDN";
        private const string MinecraftPortVariable = "MINECRAFT_PORT";
        private readonly TelemetryClient telemetryClient;

        /// Using dependency injection will guarantee that you use the same configuration for telemetry collected automatically and manually.
        public PingTest(TelemetryConfiguration telemetryConfiguration)
        {
            this.telemetryClient = new TelemetryClient(telemetryConfiguration);

        }        

        [FunctionName("PingTest")]
        public void Run(
            [TimerTrigger("0 */5 * * * *", RunOnStartup = false, UseMonitor = true)]TimerInfo timer,
            ILogger log
        )
        {
            if (timer.IsPastDue)
            {
                log.LogInformation("Timer is running late!");
            }
            log.LogInformation($"Start processing at: {DateTime.Now}");
            bool success = false;
            Stopwatch stopwatch = Stopwatch.StartNew();

            try {
                TcpClient client;
                do {
                    client = CreateClient();
                    if (!client.Connected) {
                        // HACK
                        Thread.Sleep(500);
                    }

                } 
                while (!client.Connected && stopwatch.Elapsed.TotalSeconds < 30);
                success = client.Connected;

            }
            catch (SocketException ex)
            {
                log.LogError(ex,ex.Message);

                success = false;
            }
            catch (Exception ex)
            {
                log.LogCritical(ex,ex.Message);

                // Rethrow exception
                throw;
            } 
            finally 
            {
                var properties = new Dictionary<string,string>();
                // properties.Add("ActivityId",System.Diagnostics.Activity.Current.TraceId.ToString());
                properties.Add("Connected",success.ToString());
                this.telemetryClient.TrackTrace("TestResult",SeverityLevel.Information,properties);                

                string responseMessage;
                if (success)
                {
                    responseMessage = String.Format("Minecraft Server connected in {0}",stopwatch.Elapsed.ToString(TimerFormat));
                }
                else 
                {
                    responseMessage = String.Format("Minecraft Server did not connect in {0}",stopwatch.Elapsed.ToString(TimerFormat));
                }
                log.LogInformation(responseMessage);
            }
        }

        private static TcpClient CreateClient() {
            string minecraftFQDN = GetVariableValue(MinecraftFqdnVariable);
            int minecraftPort = Convert.ToInt32(GetVariableValue(MinecraftPortVariable));
            TcpClient client = new System.Net.Sockets.TcpClient(minecraftFQDN, minecraftPort);

            return client;
        }

        private static string FormatTimers(Dictionary<string, TimeSpan> timers) {
            string result = String.Empty;

            foreach (string snapshot in timers.Keys) {
                TimeSpan timer = timers[snapshot];
                string elapsed = timer.ToString(TimerFormat);
                result += String.Format("\n{0}: {1}",snapshot,elapsed);
            }

            return result;
        }

        private static string GetVariableValue(string variableName)
        {
            string varableValue = Environment.GetEnvironmentVariable(variableName);
            if (String.IsNullOrEmpty(varableValue)) {
                throw new Exception(String.Format("Environment variable {0} not set",variableName));
            }

            return varableValue;
        }

    }
}