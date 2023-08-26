def change_product_for_plans(reseller_id)
  ActiveRecord::Base.transaction do
    reseller = Reseller.find(reseller_id)
    plans = get_plans(reseller)
    table = get_table_from_csv("/home/app/core/support/sap-17989.csv")
    table.each do |item|
      plans.each do |plan|
        if plan.sku.include? item["product_id"]
          p "Plan to process: #{plan.id}"
          create_product_categories(item["product_category_key"], item["product_category_name"], reseller)
          create_products(item["product_category_key"], item["product_name"], reseller, plan)
          update_product_for_plans(plan, item)
        end
      end
    end
  end
end

def create_product_categories(new_product_category_key, new_product_category_name, reseller, ancestry_category = nil)
  if reseller.product_categories.find_by(key: new_product_category_key).nil?
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
    p "Product category exists, new one was not created"
    new_product_category = reseller.product_categories.find_by(key: new_product_category_key)
  end
  return if reseller.childern.empty?
  reseller.children.map do |child_res|
    create_product_categories(new_product_category.key, new_product_category.name, child_res, current_ancestry_category)
  end
end

def create_products(product_category_key, new_product_name, reseller, plan, ancestry_product = nil)
  product_category_id = reseller.product_categories.find_by(key: product_category_key)
  if reseller.products.find_by(product_category_id: product_category_id, name: new_product_name).nil?
    new_product = Product.create!(
      name: new_product_name,
      product_type: plan.product.product_type,
      reseller_id: reseller.id,
      product_category_id: product_category_id,
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
    new_product = Product.find_by(product_category_id: new_product_category_id, name: new_product_name)
  end
  return if reseller.descendants.empty?
  reseller.children.map do |child_res|
    create_products(product_category_key, new_product.name, child_res, plan, current_ancestry_product)
  end
end

def update_product_for_plans(plan, item)
  new_product_category_id = plan.reseller.product_categories.find_by(key: item["product_category_key"]).id
  new_product_id = plan.reseller.products.find_by(product_category_id: new_product_category_id, name: item["product_name"]).id
  old_product_id = plan.product.id
  plan.update_columns(product_id: new_product_id)
  p "Product for plan #{plan.id} was changed from #{old_product_id} to #{new_product.id}"
  plan.children.map do |plan|
    update_product_for_plans(plan, item)
  end
end

def get_table_from_csv(path)
  f = path
  table = []
  CSV.foreach(f, headers: true) do |row|
    table << row.to_hash
  end
  return table
end

def get_plans(reseller)
  product_category_ids = reseller.product_categories.where(key: :office_365_academic).ids
  products_ids = reseller.products.where(product_category_id: product_category_ids).where("name = 'Perpetual Microsoft Education' or name = 'Бессрочные лицензии Microsoft Education'").ids
  plans = reseller.plans.where(product_id: products_ids, status: :active)
  return plans
end
