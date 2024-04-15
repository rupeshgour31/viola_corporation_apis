defmodule Violacorp.Schemas.FourstopTest do

  use Violacorp.DataCase
  alias Violacorp.Schemas.Fourstop
  @moduledoc false

  @valid_attrs %{
    commanall_id: 1232,
    director_id: 1223,
    stopid: "01252326587",
    stop_status: "Y",
    description: "Siccess",
    score: "100",
    rec: "Reject",
    confidence_level: "100",
    request: "request",
    response: "response",
    remark: "Rmearl",
    status: "D",
    inserted_by: 4545
  }
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Fourstop.changeset(%Fourstop{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Fourstop.changeset(%Fourstop{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "commanall_id required check" do
    changeset = Fourstop.changeset(%Fourstop{}, Map.delete(@valid_attrs, :commanall_id))
    assert !changeset.valid?
  end

  test "director_id required check" do
    changeset = Fourstop.changeset(%Fourstop{}, Map.delete(@valid_attrs, :director_id))
    assert !changeset.valid?
  end

  test "stopid required check" do
    changeset = Fourstop.changeset(%Fourstop{}, Map.delete(@valid_attrs, :stopid))
    assert !changeset.valid?
  end
  test "stop_status required check" do
    changeset = Fourstop.changeset(%Fourstop{}, Map.delete(@valid_attrs, :stop_status))
    assert !changeset.valid?
  end
  test "description required check" do
    changeset = Fourstop.changeset(%Fourstop{}, Map.delete(@valid_attrs, :description))
    assert !changeset.valid?
  end
  test "score required check" do
    changeset = Fourstop.changeset(%Fourstop{}, Map.delete(@valid_attrs, :score))
    assert !changeset.valid?
  end
  test "rec required check" do
    changeset = Fourstop.changeset(%Fourstop{}, Map.delete(@valid_attrs, :rec))
    assert !changeset.valid?
  end
  test "confidence_level required check" do
    changeset = Fourstop.changeset(%Fourstop{}, Map.delete(@valid_attrs, :confidence_level))
    assert !changeset.valid?
  end
  test "request required check" do
    changeset = Fourstop.changeset(%Fourstop{}, Map.delete(@valid_attrs, :request))
    assert !changeset.valid?
  end
    test "response required check" do
    changeset = Fourstop.changeset(%Fourstop{}, Map.delete(@valid_attrs, :response))
    assert !changeset.valid?
  end
    test "remark required check" do
    changeset = Fourstop.changeset(%Fourstop{}, Map.delete(@valid_attrs, :remark))
    assert !changeset.valid?
  end

      test "status required check" do
    changeset = Fourstop.changeset(%Fourstop{}, Map.delete(@valid_attrs, :status))
    assert !changeset.valid?
  end

test "inserted_by check" do
    changeset = Fourstop.changeset(%Fourstop{}, Map.delete(@valid_attrs, :inserted_by))
    assert !changeset.valid?
  end

  @doc " changesetv2"

  test "changeset with valid attributes changesetv2" do
    changeset = Fourstop.changesetv2(%Fourstop{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes changesetv2" do
    changeset = Fourstop.changesetv2(%Fourstop{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "commanall_id required check changesetv2 " do
    changeset = Fourstop.changesetv2(%Fourstop{}, Map.delete(@valid_attrs, :commanall_id))
    assert !changeset.valid?
  end

  test "commanall_id required check changesetv2" do
    changeset = Fourstop.changesetv2(%Fourstop{}, Map.delete(@valid_attrs, :commanall_id))
    assert !changeset.valid?
  end

  test "stopid required check changesetv2" do
    changeset = Fourstop.changesetv2(%Fourstop{}, Map.delete(@valid_attrs, :stopid))
    assert !changeset.valid?
  end
  test "stop_status required check changesetv2" do
    changeset = Fourstop.changesetv2(%Fourstop{}, Map.delete(@valid_attrs, :stop_status))
    assert !changeset.valid?
  end
  test "description required check changesetv2" do
    changeset = Fourstop.changesetv2(%Fourstop{}, Map.delete(@valid_attrs, :description))
    assert !changeset.valid?
  end
  test "score required check changesetv2" do
    changeset = Fourstop.changesetv2(%Fourstop{}, Map.delete(@valid_attrs, :score))
    assert !changeset.valid?
  end
  test "rec required check changesetv2" do
    changeset = Fourstop.changesetv2(%Fourstop{}, Map.delete(@valid_attrs, :rec))
    assert !changeset.valid?
  end
  test "confidence_level required check changesetv2" do
    changeset = Fourstop.changesetv2(%Fourstop{}, Map.delete(@valid_attrs, :confidence_level))
    assert !changeset.valid?
  end
  test "request required check changesetv2"  do
    changeset = Fourstop.changesetv2(%Fourstop{}, Map.delete(@valid_attrs, :request))
    assert !changeset.valid?
  end
  test "response required check changesetv2" do
    changeset = Fourstop.changesetv2(%Fourstop{}, Map.delete(@valid_attrs, :response))
    assert !changeset.valid?
  end

  test "status required check changesetv2" do
    changeset = Fourstop.changesetv2(%Fourstop{}, Map.delete(@valid_attrs, :status))
    assert !changeset.valid?
  end

  test "inserted_by check changesetv2" do
    changeset = Fourstop.changesetv2(%Fourstop{}, Map.delete(@valid_attrs, :inserted_by))
    assert !changeset.valid?
  end


  @doc" update_status"

  test "changeset with valid attributes update_status" do
    changeset = Fourstop.update_status(%Fourstop{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes update_status" do
    changeset = Fourstop.update_status(%Fourstop{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "status required check update_status" do
    changeset = Fourstop.update_status(%Fourstop{}, Map.delete(@valid_attrs, :status))
    assert !changeset.valid?
  end



end