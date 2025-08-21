class TimeSlot < ApplicationRecord
    validates :fold, inclusion: { in: [0, 1] }
end
