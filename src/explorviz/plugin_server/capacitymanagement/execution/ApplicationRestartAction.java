package explorviz.plugin_server.capacitymanagement.execution;

import explorviz.plugin_client.capacitymanagement.execution.SyncObject;
import explorviz.plugin_server.capacitymanagement.CapManRealityMapper;
import explorviz.plugin_server.capacitymanagement.cloud_control.ICloudController;
import explorviz.plugin_server.capacitymanagement.loadbalancer.ScalingGroup;
import explorviz.plugin_server.capacitymanagement.loadbalancer.ScalingGroupRepository;
import explorviz.shared.model.Application;
import explorviz.shared.model.Node;
import explorviz.shared.model.helper.GenericModelElement;

/**
 *
 * Action which restarts the given application in the cloud.
 *
 */
public class ApplicationRestartAction extends ExecutionAction {

	private final Application application;
	private final Node parent;
	private final String name;
	private final String ipParent;

	public ApplicationRestartAction(final Application app) {
		parent = app.getParent();
		ipParent = parent.getIpAddress();
		name = app.getName();
		// TODO: jkr/jek: how to deal with null?
		application = CapManRealityMapper.getApplication(ipParent, name);
	}

	@Override
	protected GenericModelElement getActionObject() {
		return application;
	}

	@Override
	protected SyncObject synchronizeOn() {
		return application;
	}

	@Override
	protected void beforeAction() {
		lockingNodeForApplications(parent);
	}

	@Override
	protected boolean concreteAction(final ICloudController controller,
			ScalingGroupRepository repository) throws Exception {
		String scalinggroupName = application.getScalinggroupName();
		ScalingGroup scalinggroup = repository.getScalingGroupByName(scalinggroupName);
		boolean success = controller.restartApplication(application, scalinggroup);

		return success;
	}

	@Override
	protected void afterAction() {

	}

	@Override
	protected void finallyDo() {
		unlockingNodeForApplications(parent);
	}

	@Override
	protected String getLoggingDescription() {
		return "restarting application " + name + " on node " + parent.getName();
	}

	@Override
	protected ExecutionAction getCompensateAction() {
		return null;
	}

	// TODO: jek/jkr: if not running: startApplication ?
	@Override
	protected void compensate(ICloudController controller, ScalingGroupRepository repository) {
		if (!controller.checkApplicationIsRunning(ipParent, application.getPid(), name)) {
			String scalinggroupName = application.getScalinggroupName();
			ScalingGroup scalinggroup = repository.getScalingGroupByName(scalinggroupName);
			scalinggroup.removeApplication(application);
			CapManRealityMapper.removeApplicationFromNode(ipParent, name);

		}
	}
}