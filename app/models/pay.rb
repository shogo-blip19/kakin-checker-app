class Pay < ApplicationRecord
  belongs_to :user
  belongs_to :preset_title
  
end
