# Support for finding the next available time and moving a reservation
# up to that next time slot
module Reservations::MovingUp
  #
  # Returns a clone of this reservation with the reserve_*_at times updated
  # to the next accommodating time slot on the calendar from NOW. Returns nil
  # if there is no such time slot. The clone is frozen so don't try to change
  # it. It's for read-only purposes.
  def earliest_possible
    clone=self.clone
    after=Time.zone.now+1.minute

    while true
      next_res=product.next_available_reservation(after, self)

      return nil if next_res.nil? or next_res.reserve_start_at > reserve_start_at

      clone.reserve_start_at=next_res.reserve_start_at
      clone.reserve_end_at=next_res.reserve_start_at.advance(:minutes => duration_mins)

      if instrument_is_available_to_reserve? && does_not_conflict_with_other_reservation?
        clone.freeze
        return clone
      end

      after=next_res.reserve_end_at
    end
  end

  #
  # Updates this reservation's reserve_*_at times
  # to that of +reservation+'s.
  # [_reservation_]
  #   The reservation whose reserve times we want to adopt.
  # [_exception_]
  #   On anything that #save! raises for
  def move_to!(reservation)
    self.reserve_start_at=reservation.reserve_start_at
    self.reserve_end_at=reservation.reserve_end_at
    save!
  end

  #
  # returns true if this reservation can be moved to
  # an earlier time slot, false otherwise
  def can_move?
    !(cancelled? || order_detail.complete? || earliest_possible.nil?)
  end
end