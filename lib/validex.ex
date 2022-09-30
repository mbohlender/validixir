defmodule Validex do
  @moduledoc """
  Module containing all basic functionality needed for validation.
  """

  # TODO: Module doc
  # TODO: Tests showing the whole thing
  # TODO: README
  # TODO: Deploy in hex

  alias Validex.Error, as: Error
  alias Validex.Failure, as: Failure
  alias Validex.Success, as: Success

  use Currying

  @type validation_result_t :: Failure.t() | Success.t()

  @doc ~S"""
  Returns `true` if a value is either a [[Validex.Success]] or a [[Validex.Failure]],
  returns `false` else.

  ## Examples

      iex> Validex.validation_result?(Validex.Success.make(12))
      true

      iex> Validex.validation_result?(Validex.Failure.make([]))
      true

      iex> Validex.validation_result?(%{})
      false
  """
  @spec validation_result?(any()) :: boolean()
  def validation_result?(thing) do
    case thing do
      %Failure{} -> true
      %Success{} -> true
      _ -> false
    end
  end

  @doc ~S"""
  Applies a function to the candidate of a success. If a failure is passed it is
  returned unchanged.

  ## Examples

      iex> success = Validex.Success.make(0)
      iex> Validex.map_success(success, fn a -> a + 1 end)
      %Validex.Success{candidate: 1}

      iex> failure = Validex.Failure.make([])
      iex> Validex.map_success(failure, fn a -> a + 1 end)
      %Validex.Failure{errors: []}
  """
  @spec map_success(validation_result_t, (any() -> any())) :: validation_result_t
  def map_success(success = %Success{}, f), do: Success.map(success, f)
  def map_success(failure = %Failure{}, _), do: failure

  @doc ~S"""
  Applies a function to the errors of a failure. If a success is passed it is
  returned unchanged.

  ## Examples

      iex> success = Validex.Success.make(0)
      iex> Validex.map_failure(success, fn a -> a + 1 end)
      %Validex.Success{candidate: 0}

      iex> failure = Validex.Failure.make([Validex.Error.make(1, :hello, :hello)])
      iex> Validex.map_failure(failure, fn err -> %Validex.Error{ err | candidate: 2} end)
      %Validex.Failure{errors: [Validex.Error.make(2, :hello, :hello)]}
  """
  @spec map_failure(validation_result_t, (Error.t() -> Error.t())) :: validation_result_t
  def map_failure(failure = %Failure{}, f), do: Failure.map(failure, f)
  def map_failure(success = %Success{}, _), do: success

  @doc ~S"""
  Takes a validation result and two functions that are applied as in map_success/2 and
  map_failure/2 respectivly.

  ## Examples

      iex> success = Validex.Success.make(0)
      iex> Validex.map(success, fn a -> a + 1 end, fn _ -> :does_nothing end)
      %Validex.Success{candidate: 1}

      iex> failure = Validex.Failure.make([Validex.Error.make(1, :hello, :hello)])
      iex> Validex.map(failure, fn _ -> :does_nothing end, fn err -> %Validex.Error{ err | candidate: 2} end)
      %Validex.Failure{errors: [Validex.Error.make(2, :hello, :hello)]}
  """
  @spec map(validation_result_t, (any() -> any()), (Error.t() -> Error.t())) ::
          validation_result_t
  def map(f = %Failure{}, _, f_failure), do: map_failure(f, f_failure)
  def map(s = %Success{}, f_success, _), do: map_success(s, f_success)

  @doc ~S"""
  Takes a value and lifts it in a validation result, returning a success with the value
  as its candidate.

  ## Examples

      iex> Validex.pure(12)
      %Validex.Success{candidate: 12}
  """
  @spec pure(any()) :: Success.t()
  def pure(value), do: Success.make(value)

  @doc ~S"""
  Augments a failure's contexts if a failure is passed, else returns the success.

  ## Examples

      iex> Validex.pure(12) |> Validex.augment_contexts(Hello)
      %Validex.Success{candidate: 12}

      iex> error_1 = Validex.Error.make(1, :message, Context)
      iex> error_2 = Validex.Error.make(2, :message, AnotherContext)
      iex> failure = Validex.Failure.make([error_1, error_2])
      iex> Validex.augment_contexts(failure, AdditionalContext)
      %Validex.Failure{
          errors: [
              %Validex.Error{candidate: 1, message: :message, context: {AdditionalContext, Context}},
              %Validex.Error{candidate: 2, message: :message, context: {AdditionalContext, AnotherContext}},
          ]
      }
  """
  @spec augment_contexts(validation_result_t(), any()) :: validation_result_t()
  def augment_contexts(s = %Success{}, _), do: s

  def augment_contexts(f = %Failure{}, additional_context),
    do: map_failure(f, fn error -> Error.augment_context(error, additional_context) end)

  @doc ~S"""
  Augments a failure's messages if a failure is passed, else returns the success.

  ## Examples

      iex> Validex.pure(12) |> Validex.augment_messages(Hello)
      %Validex.Success{candidate: 12}

      iex> error_1 = Validex.Error.make(1, :message, Context)
      iex> error_2 = Validex.Error.make(2, :another_message, Context)
      iex> failure = Validex.Failure.make([error_1, error_2])
      iex> Validex.augment_messages(failure, :additional_message)
      %Validex.Failure{
          errors: [
              %Validex.Error{candidate: 1, message: {:additional_message, :message}, context: Context},
              %Validex.Error{candidate: 2, message: {:additional_message, :another_message}, context: Context}
          ]
      }
  """
  @spec augment_messages(validation_result_t(), any()) :: validation_result_t()
  def augment_messages(s = %Success{}, _), do: s

  def augment_messages(f = %Failure{}, additional_message),
    do: map_failure(f, fn error -> Error.augment_message(error, additional_message) end)

  @doc ~S"""
  Overrides a failure's messages if a failure is passed, else returns the success.

  ## Examples

      iex> Validex.pure(12) |> Validex.override_messages(Hello)
      %Validex.Success{candidate: 12}

      iex> error_1 = Validex.Error.make(1, :message, Context)
      iex> error_2 = Validex.Error.make(2, :another_message, Context)
      iex> failure = Validex.Failure.make([error_1, error_2])
      iex> Validex.override_messages(failure, :additional_message)
      %Validex.Failure{
          errors: [
              %Validex.Error{candidate: 1, message: :additional_message, context: Context},
              %Validex.Error{candidate: 2, message: :additional_message, context: Context}
          ]
      }
  """
  @spec override_messages(validation_result_t(), any()) :: validation_result_t()
  def override_messages(s = %Success{}, _), do: s
  def override_messages(f = %Failure{}, message), do: Failure.override_error_messages(f, message)

  @doc ~S"""
  Overrides a failure's contexts if a failure is passed, else returns the success.

  ## Examples

      iex> Validex.pure(12) |> Validex.override_contexts(Hello)
      %Validex.Success{candidate: 12}

      iex> error_1 = Validex.Error.make(1, :message, Context)
      iex> error_2 = Validex.Error.make(2, :another_message, Context)
      iex> failure = Validex.Failure.make([error_1, error_2])
      iex> Validex.override_contexts(failure, NewContext)
      %Validex.Failure{
          errors: [
          %Validex.Error{candidate: 1, message: :message, context: NewContext},
          %Validex.Error{candidate: 2, message: :another_message, context: NewContext}
          ]
      }
  """
  @spec override_contexts(validation_result_t(), any()) :: validation_result_t()
  def override_contexts(s = %Success{}, _), do: s
  def override_contexts(f = %Failure{}, context), do: Failure.override_error_contexts(f, context)

  @doc ~S"""
  This function applies a function wrapped in a validation success to the
  candidate of a validation success. If both validation results are failures
  it returns them combined. If only the first one is a failure, this failure
  is returned unchanged.

  This function is key in implementing applicatives.

  ## Examples

      iex> s1 = Validex.Success.make(fn a -> a + 1 end)
      iex> s2 = Validex.Success.make(0)
      iex> Validex.seq(s1, s2)
      %Validex.Success{candidate: 1}

      iex> error = Validex.Error.make(:hello, "not allowed", nil)
      iex> failure = Validex.Failure.make([error])
      iex> success = Validex.Success.make(1)
      iex> Validex.seq(failure, success)
      %Validex.Failure{errors: [error]}

      iex> error1 = Validex.Error.make(:hello, "not allowed", nil)
      iex> error2 = Validex.Error.make(:world, "not allowed", nil)
      iex> failure1 = Validex.Failure.make([error1])
      iex> failure2 = Validex.Failure.make([error2])
      iex> Validex.seq(failure1, failure2)
      %Validex.Failure{errors: [error1, error2]}
  """
  @spec seq(validation_result_t, validation_result_t) :: validation_result_t
  def seq(f1 = %Failure{}, f2 = %Failure{}), do: Failure.combine(f1, f2)
  def seq(f1 = %Failure{}, _), do: f1
  def seq(%Success{candidate: f}, validation_result), do: map_success(validation_result, f)

  @doc !"""
       Essentially a monadic bind.
       """
  @spec bind(validation_result_t, (any() -> any())) :: validation_result_t
  defp bind(failure = %Failure{}, _), do: failure
  defp bind(%Success{candidate: candidate}, f), do: f.(candidate)

  @doc ~S"""
  Takes a `validation_result_t()` and a functions that takes the candidate
  in case of a success and returns a `validation_result_t()` again.
  This function is used to chain validations.

  ## Examples

      iex> Validex.Success.make(0) |> Validex.and_then(fn x -> Validex.Success.make(x + 1) end)
      %Validex.Success{candidate: 1}

      iex> Validex.Failure.make([]) |> Validex.and_then(fn x -> x + 1 end)
      %Validex.Failure{errors: []}
  """
  @spec and_then(validation_result_t, (any() -> validation_result_t)) :: validation_result_t
  def and_then(validation_result, f), do: bind(validation_result, f)

  @doc ~S"""
  Takes a function that is called iff all validation results are Successes. The call
  parameters are then the candidates in the respective order. Returns a validation success then,
  with the candidate being the return value of this function.
  If there is at least one failure, errors get accumulated and a validation failure is returned.

  ## Examples

      iex> Validex.validate(fn a, b -> {a, b} end, [Validex.Success.make(1), Validex.Success.make(2)])
      %Validex.Success{candidate: {1,2}}

      iex> error1 = Validex.Error.make(:hello, "not allowed", nil)
      iex> error2 = Validex.Error.make(:world, "not allowed", nil)
      iex> failure1 = Validex.Failure.make([error1])
      iex> failure2 = Validex.Failure.make([error2])
      iex> Validex.validate(fn a, b -> {a, b} end, [failure1, failure2])
      %Validex.Failure{errors: [error1, error2]}
  """
  @spec validate(function(), [validation_result_t]) :: validation_result_t
  def validate(result_f, validations) do
    pure_curried = curry(result_f) |> pure()
    Enum.reduce(validations, pure_curried, fn a, b -> seq(b, a) end)
  end

  @doc ~S"""
  Takes a list of validation results and returns a validation success containing list
  of all candidates, if all validation results are successes. Else all failures are
  combined and a validation failure is returned.

  ## Examples

      iex> Validex.sequence([Validex.Success.make(1), Validex.Success.make(2)])
      %Validex.Success{candidate: [1,2]}

      iex> error1 = Validex.Error.make(:hello, "not allowed", nil)
      iex> error2 = Validex.Error.make(:world, "not allowed", nil)
      iex> failure1 = Validex.Failure.make([error1])
      iex> failure2 = Validex.Failure.make([error2])
      iex> Validex.sequence([failure1, failure2])
      %Validex.Failure{errors: [error1, error2]}
  """
  @spec sequence([validation_result_t]) :: validation_result_t
  def sequence([]), do: pure([])
  def sequence([result]), do: result |> map_success(fn x -> [x] end)

  def sequence([x | xs]),
    do: validate(fn a, b -> [a | b] end, [x, sequence(xs)])

  @type validation_fun_t :: (any() -> validation_result_t)

  @doc ~S"""
  Does the same as `Validex.sequence/1` but applies a validation function
  to all candidates first.
  Takes an optional context to augment the results, including the index. Uses :seq if
  none is given.

  ## Examples

      iex> success_fn = fn c -> Validex.Success.make(c) end
      iex> Validex.sequence_of([1, 2], success_fn)
      %Validex.Success{candidate: [1,2]}

      iex> failure_fn = fn c -> [Validex.Error.make(c, "not allowed", nil)] |> Validex.Failure.make() end
      iex> Validex.sequence_of([:hello, :world], failure_fn)
      %Validex.Failure{
          errors: [Validex.Error.make(:hello, {{:index, 0}, "not allowed"}, nil),
                   Validex.Error.make(:world, {{:index, 1}, "not allowed"}, nil)]}
  """
  @spec sequence_of([any()], validation_fun_t) :: validation_result_t
  def sequence_of(candidates, validation_f) do
    candidates
    |> Enum.with_index()
    |> Enum.map(fn {candidate, idx} ->
      validation_f.(candidate) |> augment_messages({:index, idx})
    end)
    |> sequence()
  end

  @type validate_choice_return_t ::
          {:error, :no_validators}
          | {:error, :more_than_one_success}
          | {:ok, [validation_result_t]}

  @doc ~S"""
  Applies a list of validation functions to a candidate.
  Returns a success containing the candidate if each validation function returns a success.
  Else returns a validation failure containing errors of each failed validation.

  Takes an optional context as in `Validex.sequence_of/3`.

  ## Examples

      iex> success_fn_1 = fn c -> Validex.Success.make(c) end
      iex> success_fn_2 = fn _ -> Validex.Success.make(12) end
      iex> Validex.validate_all([success_fn_1, success_fn_2], 1)
      %Validex.Success{candidate: 1}

      iex> failure_fn = fn c -> [Validex.Error.make(c, "not allowed", nil)] |> Validex.Failure.make() end
      iex> success_fn = fn _ -> Validex.Success.make(12) end
      iex> Validex.validate_all([failure_fn, success_fn], :hello)
      %Validex.Failure{errors: [Validex.Error.make(:hello, {{:index, 0}, "not allowed"}, nil)]}
  """
  @type validate_all_return_t :: {:ok, validation_result_t} | {:error, :no_validators}
  @spec validate_all([validation_fun_t], any()) :: validate_all_return_t
  def validate_all([], _), do: {:error, :no_validators}

  def validate_all(validation_fs, candidate) do
    validated =
      validation_fs
      |> Enum.with_index()
      |> Enum.map(fn {validation_f, idx} ->
        validation_f.(candidate) |> augment_messages({:index, idx})
      end)
      |> sequence

    case validated do
      %Validex.Success{} -> Validex.Success.make(candidate)
      %Validex.Failure{} -> validated
    end
  end

end
