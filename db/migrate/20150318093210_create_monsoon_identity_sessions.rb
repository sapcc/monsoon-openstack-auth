class CreateMonsoonIdentitySessions < ActiveRecord::Migration
  def change
    create_table :monsoon_identity_sessions do |t|

      t.timestamps
    end
  end
end
