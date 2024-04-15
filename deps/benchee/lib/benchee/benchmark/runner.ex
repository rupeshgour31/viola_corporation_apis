defmodule Benchee.Benchmark.Runner do
  @moduledoc false

  # This module actually runs our benchmark scenarios, adding information about
  # run time and memory usage to each scenario.

  alias Benchee.{Benchmark, Configuration, Conversion, Scenario, Statistics, Utility.Parallel}
  alias Benchmark.{Collect, Hooks, RepeatedMeasurement, ScenarioContext}

  @doc """
  Executes the benchmarks defined before by first running the defined functions
  for `warmup` time without gathering results and them running them for `time`
  gathering their run times.

  This means the total run time of a single benchmarking scenario is warmup +
  time.

  Warmup is usually important for run times with JIT but it seems to have some
  effect on the BEAM as well.

  There will be `parallel` processes spawned executing the benchmark job in
  parallel.
  """
  @spec run_scenarios([Scenario.t()], ScenarioContext.t()) :: [Scenario.t()]
  def run_scenarios(scenarios, scenario_context) do
    if scenario_context.config.pre_check do
      Enum.each(scenarios, fn scenario -> pre_check(scenario, scenario_context) end)
    end

    function_call_overhead =
      if scenario_context.config.measure_function_call_overhead do
        determine_function_call_overhead()
      else
        0
      end

    scenario_context = %ScenarioContext{
      scenario_context
      | function_call_overhead: function_call_overhead
    }

    Enum.map(scenarios, fn scenario -> parallel_benchmark(scenario, scenario_context) end)
  end

  # This will run the given scenario exactly once, including the before and
  # after hooks, to ensure the function can execute without raising an error.
  defp pre_check(scenario, scenario_context) do
    scenario_input = Hooks.run_before_scenario(scenario, scenario_context)
    scenario_context = %ScenarioContext{scenario_context | scenario_input: scenario_input}
    _ = collect(scenario, scenario_context, Collect.Time)
    _ = Hooks.run_after_scenario(scenario, scenario_context)
    nil
  end

  @no_input Benchmark.no_input()
  @overhead_determination_time Conversion.Duration.convert_value({0.01, :second}, :nanosecond)
  defp determine_function_call_overhead do
    scenario = %Scenario{function: fn -> nil end, input: @no_input}

    scenario_context = %ScenarioContext{
      config: %Configuration{
        time: @overhead_determination_time,
        warmup: @overhead_determination_time,
        print: %{fast_warning: false}
      }
    }

    {run_times, []} = measure_scenario(scenario, scenario_context)
    %{50 => median} = Statistics.Percentile.percentiles(run_times, 50)

    median
  end

  defp parallel_benchmark(
         scenario = %Scenario{job_name: job_name, input_name: input_name},
         scenario_context = %ScenarioContext{
           printer: printer,
           config: config
         }
       ) do
    printer.benchmarking(job_name, input_name, config)

    config
    |> measure_scenario_parallel(scenario, scenario_context)
    |> add_measurements_to_scenario(scenario)
  end

  defp measure_scenario_parallel(config, scenario, scenario_context) do
    1..config.parallel
    |> Parallel.map(fn _ -> measure_scenario(scenario, scenario_context) end)
  end

  defp add_measurements_to_scenario(measurements, scenario) do
    run_times = Enum.flat_map(measurements, fn {run_times, _} -> run_times end)
    memory_usages = Enum.flat_map(measurements, fn {_, memory_usages} -> memory_usages end)

    %{
      scenario
      | run_time_data: %{scenario.run_time_data | samples: run_times},
        memory_usage_data: %{scenario.memory_usage_data | samples: memory_usages}
    }
  end

  defp measure_scenario(scenario, scenario_context) do
    scenario_input = Hooks.run_before_scenario(scenario, scenario_context)
    scenario_context = %ScenarioContext{scenario_context | scenario_input: scenario_input}
    _ = run_warmup(scenario, scenario_context)

    run_times =
      scenario
      |> run_runtime_benchmark(scenario_context)
      |> deduct_function_call_overhead(scenario_context.function_call_overhead)

    memory_usages = run_memory_benchmark(scenario, scenario_context)
    Hooks.run_after_scenario(scenario, scenario_context)

    {run_times, memory_usages}
  end

  defp run_warmup(
         scenario,
         scenario_context = %ScenarioContext{
           config: %Configuration{warmup: warmup}
         }
       ) do
    measure_runtimes(scenario, scenario_context, warmup, false)
  end

  defp run_runtime_benchmark(
         scenario,
         scenario_context = %ScenarioContext{
           config: %Configuration{
             time: run_time,
             print: %{fast_warning: fast_warning}
           }
         }
       ) do
    measure_runtimes(scenario, scenario_context, run_time, fast_warning)
  end

  defp deduct_function_call_overhead(run_times, 0) do
    run_times
  end

  defp deduct_function_call_overhead(run_times, overhead) do
    Enum.map(run_times, fn time ->
      max(time - overhead, 0)
    end)
  end

  defp run_memory_benchmark(_, %ScenarioContext{config: %{memory_time: 0.0}}) do
    []
  end

  defp run_memory_benchmark(
         scenario,
         scenario_context = %ScenarioContext{
           config: %Configuration{
             memory_time: memory_time
           }
         }
       ) do
    end_time = current_time() + memory_time

    new_context = %ScenarioContext{
      scenario_context
      | current_time: current_time(),
        end_time: end_time
    }

    do_benchmark(scenario, new_context, Collect.Memory, [])
  end

  defp measure_runtimes(scenario, context, run_time, fast_warning)
  defp measure_runtimes(_, _, 0.0, _), do: []

  defp measure_runtimes(scenario, scenario_context, run_time, fast_warning) do
    end_time = current_time() + run_time
    :erlang.garbage_collect()

    {num_iterations, initial_run_time} =
      RepeatedMeasurement.determine_n_times(scenario, scenario_context, fast_warning)

    new_context = %ScenarioContext{
      scenario_context
      | current_time: current_time(),
        end_time: end_time,
        num_iterations: num_iterations
    }

    do_benchmark(scenario, new_context, Collect.Time, [initial_run_time])
  end

  defp current_time, do: :erlang.system_time(:nano_seconds)

  # `run_times` is kept separately from the `Scenario` so that for the
  # `parallel` execution case we can easily concatenate and flatten the results
  # of all processes. That's why we add them to the scenario once after
  # measuring has finished. `scenario` is still needed in general for the
  # benchmarking function, hooks etc.
  defp do_benchmark(
         _scenario,
         %ScenarioContext{
           current_time: current_time,
           end_time: end_time
         },
         _collector,
         measurements
       )
       when current_time > end_time do
    # restore correct order - important for graphing
    Enum.reverse(measurements)
  end

  defp do_benchmark(scenario, scenario_context, collector, measurements) do
    measurement = collect(scenario, scenario_context, collector)
    updated_context = %ScenarioContext{scenario_context | current_time: current_time()}

    do_benchmark(
      scenario,
      updated_context,
      collector,
      updated_measurements(measurement, measurements)
    )
  end

  # We return `nil` if memory measurement failed so keep it empty
  defp updated_measurements(nil, measurements), do: measurements
  defp updated_measurements(measurement, measurements), do: [measurement | measurements]

  @doc """
  Takes one measure with the given collector.

  Correctly dispatches based on the number of iterations to perform.
  """
  def collect(
        scenario = %Scenario{function: function},
        scenario_context = %ScenarioContext{
          num_iterations: 1
        },
        collector
      ) do
    new_input = Hooks.run_before_each(scenario, scenario_context)
    function = main_function(function, new_input)

    {measurement, return_value} = collector.collect(function)

    Hooks.run_after_each(return_value, scenario, scenario_context)
    measurement
  end

  def collect(
        scenario,
        scenario_context = %ScenarioContext{
          num_iterations: iterations
        },
        collector
      )
      when iterations > 1 do
    RepeatedMeasurement.collect(scenario, scenario_context, collector)
  end

  def main_function(function, @no_input), do: function
  def main_function(function, input), do: fn -> function.(input) end
end
