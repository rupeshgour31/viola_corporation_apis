defmodule Violacorp.Models.Fees do
  import Ecto.Query

  alias Violacorp.Repo
  alias Violacorp.Schemas.Feehead
  alias Violacorp.Schemas.Groupfee

  @doc "get all fee head"
  def get_all_feehead(params)do

    title = params["title"]

    (from f in Feehead, select: %{id: f.id, inserted_at: f.inserted_at,inserted_by: f.inserted_by,status: f.status, title: f.title})
      |> where([f], like(f.title, ^"%#{title}%"))
      |> order_by(desc: :updated_at)
      |> Repo.paginate(params)
  end

  @doc "get all group head"
   def get_all_group_head(params)do
    filtered = params
               |> Map.take(~w( status amount trans_type commanall_id))
               |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)

    (from g in Groupfee,
          having: ^filtered,
          where: is_nil(g.commanall_id),
          left_join: f in assoc(g, :feehead),
          order_by: [desc: g.updated_at],
            select: %{id: g.id, title: f.title, trans_type: g.trans_type, fee_type: g.fee_type, mode: g.mode, amount: g.amount, as_default: g.as_default, status: g.status, rules: g.rules, inserted_at: g.inserted_at, updated_at: g.updated_at}
      )
    |> Repo.paginate(params)
  end

  @doc "update fee head"
  def edit_fee_head(params,admin_id)do
          getFeehead = Repo.get_by(Feehead, id: params["id"])
          if !is_nil(getFeehead)do
                  feehead = %{
                    "title" => params["title"],
                    "inserted_by" => "99999#{admin_id}",
                  }
                  changeset = Feehead.changeset(getFeehead, feehead)
                  case Repo.update(changeset)do
                    {:ok, _changeset}->    {:ok, "Record Updated"}
                    {:error, changeset} -> {:error, changeset}

                  end
           else
            {:not_found, "Record not found"}
          end
  end

  @doc "get single fee head"
  def get_single_feehead(params)do
         getFeehead = Repo.one(from f in Feehead, where: f.id == ^params["id"])
         case getFeehead do
              nil ->
              {:not_found, "record not found"}
              data ->
              {:ok, data}
        end
  end

  @doc "add new fee head"
  def add_fee_head(params)do
    feehead = %{
      "title" => params["title"],
      "status" => "A",
      "inserted_by" => params["inserted_by"]
    }
    changeset = Feehead.changeset(%Feehead{}, feehead)
    case Repo.insert(changeset) do
      {:ok, _changeset}->     {:ok, "FeeHead Added."}
      {:error, changeset} -> {:error, changeset}
    end
  end

   def feeHeadList(_params)do
      _getFeehead =  Repo.all(from f in Feehead,
                              where: f.status == "A",
                              select: %{id: f.id,
                                inserted_at: f.inserted_at,
                                inserted_by: f.inserted_by,
                                status: f.status,
                                title: f.title})
   end

  def insertGroupFees(params) do
    check_entry = Repo.get_by(Groupfee, feehead_id: params["feehead_id"], as_default: "Yes", status: "A")
    if is_nil(check_entry) do
      groupfee = %{
        "feehead_id" => params["feehead_id"],
        "amount" => params["amount"],
        "fee_type" => params["fee_type"],
        "trans_type" => params["trans_type"],
        "as_default" => "Yes",
        "rules" => Poison.encode!(params["rules"]),
        "status" => "A",
        "inserted_by" => params["inserted_by"]
      }

      changeset = Groupfee.changeset(%Groupfee{}, groupfee)
      case Repo.insert(changeset) do
        {:ok, _groupfee} -> {:ok, "GroupFee Added."}
        {:error, changeset} -> {:error, changeset}
      end
    else
      {:error_message, "Record Already Added."}
    end
  end

  def updateGroupFees(params) do
    getGroupfee = Repo.get_by(Groupfee, id: params["id"])
    if !is_nil(getGroupfee) do
      groupfee = %{
        "amount" => params["amount"],
        "fee_type" => params["fee_type"],
        "trans_type" => params["trans_type"],
        "rules" => Poison.encode!(params["rules"]),
      }
      changeset = Groupfee.changeset(getGroupfee, groupfee)
      case Repo.update(changeset) do
        {:ok, _feehead} -> {:ok, "GroupFee Updated."}
        {:error, changeset} -> {:error, changeset}
      end
    else
      {:error_message, "Record Not Found."}
    end
  end
end


