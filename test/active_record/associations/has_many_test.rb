require 'test_helper'

class ActiveRecord::Associations::HasManyTest < Minitest::Test

  test 'x' do
    webmock(:get, "/fleets", where: {id: 42}, limit: 1).to_return(body: [{id: 42, name: "Spanish Armada"}].to_json)
    webmock(:get, "/ships", where: {fleet_id: 42}).to_return(body: [].to_json)

    Fleet.find(42).ships << Ship.new(name: 'São Martinho')
    assert_equal 42, 12
  end

  test '#save includes modified has_many associations' do
    webmock(:get, '/fleets', where: {id: 1}, limit: 1, include: [:ships]).to_return({
      body: [{
        id: 1,
        name: 'Armada Trio',
        ships: [
          {id: 2, fleet_id: 1, name: 'Definant'}
        ]
      }].to_json
    })

    req_stub = webmock(:patch, '/fleets/1').with(
      body: {
        fleet: {
          ships_attributes: [{ fleet_id: nil, name: 'Voyager' }]
        }
      }.to_json
    ).to_return(
      body: {
        id: 1,
        name: 'Armada Trio',
        ships: [{ id: 3, fleet_id: 1, name: 'Voyager' }]
      }.to_json
    )

    # fleet.ships = [ship]
    fleet = Fleet.eager_load(:ships).find(1)
    assert fleet.update(ships: [Ship.new(name: 'Voyager')])
    assert_equal 1, fleet.id
    assert_equal [3], fleet.ships.map(&:id)
    # assert_equal 3, ship.fleet.id
    # assert_equal 'Definant 001', ship.name
    # assert_equal 'Armada 2', ship.fleet.name

    assert_requested req_stub
  end

end
