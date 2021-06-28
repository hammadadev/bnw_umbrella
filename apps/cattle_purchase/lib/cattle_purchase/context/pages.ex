defmodule CattlePurchase.Pages do
  def list_pages() do
    [
      %{name: "Page", url: "/cattle_purchase/page"},
      %{name: "Purchase Type", url: "/cattle_purchase/purchase_type"},
      %{name: "Purchase Group", url: "/cattle_purchase/purchase_group"}
    ]
  end
end
