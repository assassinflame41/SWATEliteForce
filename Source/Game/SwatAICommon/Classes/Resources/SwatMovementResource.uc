///////////////////////////////////////////////////////////////////////////////
class SwatMovementResource extends Tyrion.AI_MovementResource;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

var DistanceSensorAction	MovementDistanceSensorAction;

///////////////////////////////////////////////////////////////////////////////
//
// Initialization / Cleanup

event init()
{
	super.init();

	MovementDistanceSensorAction = DistanceSensorAction(addSensorActionClass( class'DistanceSensorAction' ));
}

function cleanup()
{
	MovementDistanceSensorAction = None;

	super.cleanup();
}