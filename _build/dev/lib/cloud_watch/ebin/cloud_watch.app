{application,cloud_watch,
             [{applications,[kernel,stdlib,elixir,logger]},
              {description,"Amazon CloudWatch-logger backend for Elixir"},
              {modules,['Elixir.CloudWatch','Elixir.CloudWatch.AwsProxy',
                        'Elixir.CloudWatch.InputLogEvent',
                        'Elixir.Poison.Encoder.CloudWatch.InputLogEvent']},
              {registered,[]},
              {vsn,"0.3.2"}]}.
