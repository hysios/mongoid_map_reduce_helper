require File.expand_path('../spec_helper', __FILE__)

def print_table(result)
  table = Terminal::Table.new do |t|
    row = result.first
    heads = row["value"].map{ |k,v| k }
    t.headings = [ "_id", *heads]
    result.each do |row|
      id, value =  row["_id"], row["value"]
      t.add_row [id , *(heads.map{ |k| value[k] })]
    end
  end
  puts table
end

rows = Product
  .algorithm(:group_by)
  .group_by(:customer)
  .columns(count: :'$count(customer)', total: :'$sum(price)')
  .to_a

<<-SQL
  SELECT count(customer) AS count, sum(price) AS total FROM products GROUP BY customer HAVING sum(price) > 1000
SQL

print_table(rows)

print_table(Product
  .algorithm(:group_by)
  .group_by(:customer)
  .columns(count: :'$count(customer)', total: :'$sum(price)', min_order: :'$min(price)')
  .to_a)

print_table(Product
  .algorithm(:group_by)
  .group_by(:customer)
  .columns(count: :'$count(customer)', total: :'$sum(price)', max_order: :'$max(price)')
  .to_a)

print_table(Product
  .where(customer: 'Bush')
  .algorithm(:group_by)
  .group_by(:customer)
  .columns(:customer, count: :'$count(customer)', total: :'$sum(price)', mean_price: :'$average(price)')
  .to_a)

print_table(Product
  .algorithm(:group_by)
  .group_by(:customer)
  .columns(:customer, count: :'$count(customer)', total: :'$sum(price)', mean_price: :'$average(price)')
  .having(:'$average(price)' => '> 1000')
  .to_a)