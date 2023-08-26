def change_product_for_plans(reseller_id)
  reseller = Reseller.find(reseller_id)
  product_category_ids = reseller.product_categories.where(key: :office_365_academic).ids
  products_ids = reseller.products.where(product_category_id: product_category_ids).where("name = 'Perpetual Microsoft Education' or name = 'Бессрочные лицензии Microsoft Education'").ids
  plans = reseller.plans.where(product_id: products_ids, status: :active)
  if plans.empty?
    p "Plans with product_category_key: 'office_365_academic' and product_name: 'Perpetual Microsoft Education' missing, the method will be stopped"
    return
  end
  f = "/home/app/core/support/sap-17989.csv"
  table = []
  CSV.foreach(f, headers: true) do |row|
    table << row.to_hash
  end
  table.each do |item|
    plans.map do |plan|
      if plan.sku.include? item["product_id"]
        p "Plan to process: #{plan.id}"
        create_categories_and_products(item["product_name"], item["product_category_key"], item["product_category_name"], reseller, plan)
        product_category_id = plan.reseller.product_categories.where(key: item["product_category_key"]).last.id
        new_product = plan.reseller.products.where(product_category_id: product_category_id, name: item["product_name"]).last
        old_product_id = plan.product.id
        plan.update_columns(product_id: new_product.id)
        plan.children.map do |plan|
          child_res = plan.reseller
          child_prod = new_product.children.where(reseller_id: child_res.id).last
          plan.update_columns(product_id: child_prod.id)
        end
        p "Product for plan #{plan.id} was changed from #{old_product_id} to #{new_product.id}"
      end
    end
  end
  reseller = Reseller.find(reseller_id)
  product_category_ids = reseller.product_categories.where(key: :office_365_academic).ids
  products_ids = reseller.products.where(product_category_id: product_category_ids).where("name = 'Perpetual Microsoft Education' or name = 'Бессрочные лицензии Microsoft Education'").ids
  plans = reseller.plans.where(product_id: products_ids)
  plans.pluck(:status)
end
def create_categories_and_products(new_product_name, new_product_category_key, new_product_category_name, reseller, plan, ancestry_category = nil, ancestry_product = nil)
  if reseller.product_categories.where(key: new_product_category_key).empty?
    new_product_category = ProductCategory.create!(
      name: new_product_category_name,
      key: new_product_category_key,
      ancestry: ancestry_category,
      reseller_id: reseller.id,
      priority: 100,
      color: "gray",
      public: false
    )
    p "Created new ProductCategory: #{new_product_category.name} with id: #{new_product_category.id}"
    current_ancestry_category = ancestry_category ? (ancestry_category + '/' + new_product_category.id.to_s) : new_product_category.id.to_s
  else
    p "ProductCategory exists, new one was not created"
    new_product_category = reseller.product_categories.where(key: new_product_category_key).last
  end
  if reseller.products.where(product_category_id: new_product_category.id).where(name: new_product_name).empty?
    new_product = Product.create!(
      name: new_product_name,
      product_type: plan.product.product_type,
      reseller_id: reseller.id,
      product_category_id: new_product_category.id,
      ancestry: ancestry_product,
      public: plan.product.public,
      wizard_status: plan.product.wizard_status,
      wizard_step: plan.product.wizard_step,
      external: plan.product.external,
      subscription_name_mask: plan.product.subscription_name_mask
    )
    p "Created new Product: #{new_product.name} with id:#{new_product.id}"
    current_ancestry_product = ancestry_product ? (ancestry_product + '/' + new_product.id.to_s) : new_product.id.to_s
  else
    p "Product exists, new one was not created"
    new_product = Product.where(product_category_id: new_product_category.id).where(name: new_product_name).last
  end
  return if reseller.descendants.empty?
  reseller.children.map do |child_res|
    create_categories_and_products(new_product.name, new_product_category.key, new_product_category.name, child_res, plan, current_ancestry_category, current_ancestry_product)
  end
end
