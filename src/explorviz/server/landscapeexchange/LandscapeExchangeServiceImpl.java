package explorviz.server.landscapeexchange;

import java.io.*;

import com.esotericsoftware.kryo.Kryo;
import com.esotericsoftware.kryo.io.Input;
import com.google.gwt.user.server.rpc.RemoteServiceServlet;

import explorviz.server.experiment.LandscapeReplayer;
import explorviz.server.main.Configuration;
import explorviz.server.main.FileSystemHelper;
import explorviz.server.repository.*;
import explorviz.shared.model.Landscape;
import explorviz.visualization.landscapeexchange.LandscapeExchangeService;

public class LandscapeExchangeServiceImpl extends RemoteServiceServlet
		implements LandscapeExchangeService {

	private static final long serialVersionUID = 4310863128987822861L;
	private static LandscapeRepositoryModel model;

	private static long timestamp = 1467188123864L;
	private static long activity = 6247035;

	static String FULL_FOLDER = FileSystemHelper.getExplorVizDirectory() + File.separator
			+ "replay";

	static {
		startRepository();
	}

	public Landscape getLandscapeByTimestampAndActivity(final long timestamp, final long activity) {
		LandscapeExchangeServiceImpl.timestamp = timestamp;
		LandscapeExchangeServiceImpl.activity = activity;
		return getCurrentLandscape();
	}

	public static LandscapeRepositoryModel getModel() {
		return model;
	}

	@Override
	public Landscape getCurrentLandscape() {
		if (Configuration.experiment) {
			final LandscapeReplayer replayer = LandscapeReplayer.getReplayerForCurrentUser();

			return replayer.getCurrentLandscape();
		} else {
			// IMPORTANT: Kryo depends heavily on used JDK version for
			// serialization.
			// Landscapes that are serialized with an older JDK
			// are not supported for deserialization.

			// return LandscapeDummyCreator.createDummyLandscape();
			return getLandscape(timestamp, activity);
			// return model.getLastPeriodLandscape();
		}
	}

	private Landscape getLandscape(final long timestamp, final long activity) {
		Input input = null;
		Landscape landscape = null;
		try {
			input = new Input(new FileInputStream(FULL_FOLDER + File.separator + timestamp + "-"
					+ activity + Configuration.MODEL_EXTENSION));
			final Kryo kryo = RepositoryStorage.createKryoInstance();
			landscape = kryo.readObject(input, Landscape.class);
		} catch (final FileNotFoundException e) {
			e.printStackTrace();
		} finally {
			if (input != null) {
				input.close();
			}
		}

		return LandscapePreparer.prepareLandscape(landscape);
	}

	@Override
	public Landscape getLandscape(final long timestamp) {
		try {
			if (Configuration.experiment) {
				final LandscapeReplayer replayer = LandscapeReplayer.getReplayerForCurrentUser();

				return replayer.getLandscape(timestamp);
			} else {
				return model.getLandscape(timestamp);
			}
		} catch (final FileNotFoundException e) {
			e.printStackTrace();
			return null;
		}
	}

	@Override
	public void resetLandscape() {
		model.reset();
	}

	private static void startRepository() {
		model = new LandscapeRepositoryModel();
		new Thread(new Runnable() {

			@Override
			public void run() {
				new RepositoryStarter().start(model);
			}
		}).start();
	}
}