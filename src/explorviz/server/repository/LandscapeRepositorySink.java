package explorviz.server.repository;

import explorviz.live_trace_processing.filter.*;
import explorviz.live_trace_processing.record.IRecord;

public final class LandscapeRepositorySink extends AbstractSink implements ITraceSink {
	private final LandscapeRepositoryModel model;
	private final SinglePipeConnector<RecordArrayEvent> modelConnector;

	public LandscapeRepositorySink(final SinglePipeConnector<RecordArrayEvent> modelConnector,
			final LandscapeRepositoryModel model) {
		super();
		this.modelConnector = modelConnector;
		this.model = model;
	}

	@Override
	public void run() {
		modelConnector.process(this);
	}

	@Override
	protected void processRecord(final IRecord record) {
		model.insertIntoModel(record);
	}
}
