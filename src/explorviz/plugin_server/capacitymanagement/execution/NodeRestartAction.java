package explorviz.plugin_server.capacitymanagement.execution;

import java.util.List;

import explorviz.plugin_client.capacitymanagement.execution.SyncObject;
import explorviz.plugin_server.capacitymanagement.CapManRealityMapper;
import explorviz.plugin_server.capacitymanagement.cloud_control.ICloudController;
import explorviz.plugin_server.capacitymanagement.loadbalancer.ScalingGroup;
import explorviz.plugin_server.capacitymanagement.loadbalancer.ScalingGroupRepository;
import explorviz.shared.model.Application;
import explorviz.shared.model.Node;
import explorviz.shared.model.helper.GenericModelElement;

public class NodeRestartAction extends ExecutionAction {

	private final Node node;
	private final String ipAddress;
	List<Application> apps;

	public NodeRestartAction(final Node node) {
		this.node = node;
		ipAddress = node.getIpAddress();
		apps = CapManRealityMapper.getApplicationsFromNode(ipAddress);
	}

	@Override
	protected GenericModelElement getActionObject() {
		return node;
	}

	@Override
	protected SyncObject synchronizeOn() {
		return node;
	}

	@Override
	protected void beforeAction() {

	}

	@Override
	protected boolean concreteAction(final ICloudController controller,
			ScalingGroupRepository repository) throws Exception {
		for (Application app : apps) {
			String scalinggroupName = app.getScalinggroupName();
			ScalingGroup scalinggroup = repository.getScalingGroupByName(scalinggroupName);
			scalinggroup.removeApplication(app);
			controller.terminateApplication(app, scalinggroup); // success is
			// not important
			// here
		}
		boolean success = controller.restartNode(node);
		if (success) {
			String pid;
			for (Application app : apps) {
				String scalinggroupName = app.getScalinggroupName();
				ScalingGroup scalinggroup = repository.getScalingGroupByName(scalinggroupName);
				pid = controller.startApplication(app, scalinggroup);
				if (pid == "null") {
					return false;
				} else {
					app.setPid(pid);

					scalinggroup.addApplication(app);
				}

			}
		} else {
			for (Application app : apps) {
				CapManRealityMapper.removeApplicationFromNode(ipAddress, app.getName());
			}
		}
		return success;
	}

	@Override
	protected void afterAction() {

	}

	@Override
	protected void finallyDo() {
		// nothing happens
	}

	@Override
	protected String getLoggingDescription() {
		return "restarting node " + node.getName() + " with IP: " + node.getIpAddress();
	}

	@Override
	protected ExecutionAction getCompensateAction() {
		return null;
	}

	@Override
	protected void compensate(ICloudController controller, ScalingGroupRepository repository)
			throws Exception {
		// TODO jkr jek: neuer Knoten mit anderer IP als compensate sinnvoll?
		// wichtig w�re wahrscheinlich vor allem Aufr�umen in Mapper und
		// scalinggroups?

		String newIp = "null";
		if (!controller.instanceExisting(ipAddress)) {
			CapManRealityMapper.removeNode(ipAddress);
			newIp = controller.startNode(node.getParent(), node);
		}
		if (newIp != "null") {
			node.setIpAddress(newIp);
			CapManRealityMapper.addNode(newIp);
			for (Application app : apps) {

				String scalinggroupName = app.getScalinggroupName();
				ScalingGroup scalinggroup = repository.getScalingGroupByName(scalinggroupName);

				String pid = controller.startApplication(app, scalinggroup);
				if (!pid.equals("null")) {
					scalinggroup.addApplication(app);
					CapManRealityMapper.addApplicationtoNode(newIp, app);
				}

			}
		}
	}
}
