product_cat_ids = ProductCategory.where(key: "gsuite").ids
products = Product.where(product_category: product_cat_ids)
plans = Plan.where(product_id: products.ids)
PlanResource.where(plan_id: plans.ids, name: "Users")