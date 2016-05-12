require 'test_helper'

class ActiveRecord::PersistanceTest < Minitest::Test
  
  class TestModelA < ExampleRecord
  end
  class TestModelB < ExampleRecord
    before_save do
      TestModelA.create
    end
  end
  
  test '#create with errors' do
    req_stub = webmock(:post, "/fleets").with(
      body: { fleet: {} }.to_json
    ).to_return(
      status: 400,
      body: {name: 'Armada Uno', errors: {name: 'is required'}}.to_json
    )
    
    fleet = Fleet.create()
    assert_equal ["is required"], fleet.errors[:name]
    assert_requested req_stub
  end
  
  test '#save' do
    req_stub = webmock(:post, "/fleets").with(
      body: { fleet: {name: 'Armada Uno'} }.to_json
    ).to_return(
      body: {id: 1, name: 'Armada Uno'}.to_json
    )
    
    Fleet.create(name: 'Armada Uno')
    
    assert_requested req_stub
  end
  
  test '#save attempts another request while in transaction' do
    webmock(:get, '/test_model_bs/schema').to_return(
      body: {
        id: {type: 'integer', primary_key: true, null: false, array: false},
        name: {type: 'string', primary_key: false, null: true, array: false}
      }.to_json
    )
    webmock(:get, '/test_model_as/schema').to_return(
      body: {
        id: {type: 'integer', primary_key: true, null: false, array: false},
        name: {type: 'string', primary_key: false, null: true, array: false}
      }.to_json
    )
    
    assert_raises ActiveRecord::StatementInvalid do
      TestModelB.create
    end
  end
  
  test '#save includes modified belongs_to associations' do
    ship = Ship.new(name: 'Definant', fleet: Fleet.new(name: 'Armada Duo'))
    
    req_stub = webmock(:post, '/ships', {include: :fleet}).with(
      body: {
        ship: {
          name: 'Definant',
          fleet_attributes: {
            name: 'Armada Duo'
          }
        }
      }.to_json
    ).to_return(
      body: {
        id: 2,
        fleet_id: 3,
        name: 'Definant 001',
        fleet: {
          id: 3,
          name: 'Armada 2'
        }
      }.to_json
    )
    
    assert ship.save
    assert_equal 2, ship.id
    assert_equal 3, ship.fleet_id
    assert_equal 3, ship.fleet.id
    assert_equal 'Definant 001', ship.name
    assert_equal 'Armada 2', ship.fleet.name
    
    assert_requested req_stub
  end
  
  test '#update' do
    webmock(:get, "/ships", where: {id: 1}, limit: 1).to_return(
      body: [{id: 1, name: 'Armada Uno'}].to_json
    )
    req_stub = webmock(:patch, "/ships").with(
      body: { ship: { name: 'Armada Trio' } }.to_json
    ).to_return(
      body: {id: 1, name: 'Armada Trio'}.to_json
    )
    
    
    Ship.find(1).update(name: 'Armada Trio') 
    
    assert_requested req_stub

  end
end