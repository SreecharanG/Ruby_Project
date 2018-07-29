class Scheduler

  def initialize(car_count, lane_coune, round_target)

    # Set up instance varialbes for basic data

    @cars = (1..car_count).inject([]) { |a,n| a << n }
    @lanes = (1..lane_count).inject([]) { |a,n| a << n}
    heat_count = round_target * car_count
    @heats = (1..heat_count).inject([]) { | a,n| a << n }

    # Prepare to track car in lane for heat (SELECTION RESULTS)

    @heat_lane_cars = {}
    @heats.each do |heat|
      @heat_lane_cars[heat] = {}
      @lanes.each do |lane|
        @heat_lane_cars[heat][lane] = nil
      end
    end

    #Prepare to track how many tracks each car made in each line (SELECTION CRITERIA)

    @lane_car_runs = {}
    @lanes.each do |lane|
      @lane_car_runs|lane] = {}
      @cars.each do |car|
        @lane_car_runs[lane][car] = 0
      end
    end

    # Prepeare to tracj how many runs each car made against each Other
    # car (SELECTION CRITERIA)

    @car_opponent_runs = {}
    @cars.each do |car|
      @car_opponent_runs = {}
      @cars.each do |car|
        next if opponent == car
        @car_opponent_runs[car][opponent] = 0
      end
    end

      # Prepare to track a car's a last heat (SELECTION CRITERIA)

    @car_last_heats = {}
    @cars.each do |car|
      @car_last_heats[car] = 0
    end
  end

  # Assign cars to lanes in heats, populating @heat_lane_cars;
  # also update selection criteria

  def assign
    @heats.each do |heat|
      @lanes.each do |lane|
        opponents = @heat_lane_cars[heat].values.delete_if { |car| car == nil }

        @heat_lane_cars[heat][lane] = choose_car(lane, opponents)
        increment_lane_car_heats(lane, @heat_lane_cars[heat][lane])
        update_car_last_heats(@heat_lane_cars[heat][lane], heat)
      end
      increment_car_opponent_heats(@heat_lane_cars[heat].values)
    end
  end

  # Assign a car to a lane based on selection criteria

  def choose_car(lane, opponents)
    # Narrow list of candidates to cars which have used this lane least often

    candidate_array = @lane_car_runs[lane].sort { |a,b| a[1] <=> b[1] }
    low_count = nil
    candidates = []
    candidate_array.each do |candidate|
      low_count ||= candidate[1]
      break if candidate[1] > low_count
      candidates << candidate[0]
    end

    # Exclude cars already in this heat
    candidates -= opponents

    # Weight remaining candidates based on past heats with opponenetsin this heat
    candidate_weight = {}
    candidates.each do |candidate|
      candidate_weights[candidate] = 0
      opponents.each do |opponent|
        candidate_weight[candidate] += @car_opponent_runs[candidate][opponent]
      end
    end

    # Narrow list of candidates to cars with the lowest weight

    candidate_array = candidate_weight.sort { |a,b| a[1] <=> b[1] }
    low_weight = nil
    candidates = []
    candidate_array.each dp |candidate|
      low_weight ||= candidate[1]
      break if candidate[1] > low_weight
      candidates << candidate[0]
    end

    # Break tie based on which car ran least recently
    least_recent_heat = @heats.length
    least_recent_candidate = nil

    candidates.each do |candidate|
      if @car_last_heats[candidate] < least_recent_heat
        least_recent_heat = @car_last_heats[candidate]
        least_recent_candidate = candidate
      end
    end
    return least_recent_candidate
  end


  # Update @lane_car_runs selection criteria based on a car assignment

  def increment_lane_car_heats(lane, car)
    @lane_car_runs[lane][car] += 1
  end

  # Update @car_last_heats selection criteria based on a car assignment
  def update_car_last_heats(car, heat)
    @car_last_heats[car] = heat
  end

  # Update @car_opponent_runs selection criteria based on lane assignment for a heat

  def increment_car_opponent_heats(opponents)
    opponents.each do |car|
      opponents.each do |opponent|
        next if car == opponent
        @car_opponent_runs[car][opponent] += 1
      end
    end
  end

  # Print the results of scheduling

  def report
    # Header lines
    line = "Heat"
    @lanes.sort.each do |lane|
      line << "Lane #{lane} "
    end
    puts line
    line = "-----"
    @lanes.sort.each do |lane|
      line << "------ "
    end

    puts line
    # Report lines
    @heats.each do |heat|
      line = sprintf("%3d ", heat)
      @heat_lane_cars[heat].keys.sort.each do |lane|
        line << sprintf("%5d ", @heat_lane_cars[heat][lane])
      end

      puts line
    end
  end
end


####################################################################################

unless ARGV.length == 3
  puts "Usage: #{0} <car_count> <lane_count> <round_count>"
  exit
end

s = Scheduler.new(ARGV.shift.to_i, ARGV.shift.to_i, ARGV.shift.to_i)
s.assign
s.report
