package explorviz.plugin_server.rootcausedetection.algorithm;

import java.util.*;
import java.util.concurrent.ConcurrentHashMap;

import explorviz.plugin_server.rootcausedetection.RanCorrConfiguration;
import explorviz.plugin_server.rootcausedetection.exception.RootCauseThreadingException;
import explorviz.plugin_server.rootcausedetection.model.RanCorrLandscape;
import explorviz.plugin_server.rootcausedetection.util.Maths;
import explorviz.plugin_server.rootcausedetection.util.RCDThreadPool;
import explorviz.shared.model.Clazz;
import explorviz.shared.model.CommunicationClazz;

/**
 * This class contains an elaborated algorithm to calculate RootCauseRatings. It
 * uses the data of all directly and indirectly connected classes and advanced
 * power means for aggregation.
 *
 * @author Jens Michaelis, Christian Wiechmann
 *
 */
public class MeshAlgorithm extends AbstractRanCorrAlgorithm {

	// Maps used in the landscape, required for adapting the ExplorViz Landscape
	// to a RanCorr Landscape
	private Map<Integer, ArrayList<Double>> anomalyScores;
	private Map<Integer, Double> RCRs;
	private Map<Integer, ArrayList<Integer>> sources;
	private Map<Integer, ArrayList<Integer>> targets;
	private Map<String, Integer> weights;

	// Defined as in Marwede et al
	private double p = RanCorrConfiguration.PowerMeanExponentOperationLevel;
	private double z = RanCorrConfiguration.DistanceIntensityConstant;

	// Internal error state
	private double errorState = -2.0d;

	// Record used to store the upper Call Relations:
	private class Record {
		int distance = 0;
		int weight = 0;
		double rcr = errorState;
	}

	/**
	 * Calculate RootCauseRatings in a RanCorrLandscape and uses Anomaly Scores
	 * in the ExplorViz landscape.
	 *
	 * @param lscp
	 *            specified landscape
	 */
	public void calculate(final RanCorrLandscape lscp) {
		// Reinitialize the landscape data
		anomalyScores = new ConcurrentHashMap<Integer, ArrayList<Double>>();
		RCRs = new ConcurrentHashMap<Integer, Double>();
		sources = new ConcurrentHashMap<Integer, ArrayList<Integer>>();
		targets = new ConcurrentHashMap<Integer, ArrayList<Integer>>();
		weights = new ConcurrentHashMap<String, Integer>();

		// Generate the landscape data
		generateMaps(lscp);
		generateRCRs();

		// Start the final calculation with Threads
		final RCDThreadPool<Clazz> pool = new RCDThreadPool<>(this,
				RanCorrConfiguration.numberOfThreads);

		for (final Clazz clazz : lscp.getClasses()) {
			pool.addData(clazz);
		}

		try {
			pool.startThreads();
		} catch (final InterruptedException e) {
			throw new RootCauseThreadingException(
					"MeshRanCorrAlgorithm#calculate(...): Threading interrupted, broken output.");
		}
	}

	/**
	 * The calculation method on class level started by the Thread Pool and
	 * setting the root cause rating in the observed class
	 */
	@Override
	public void calculate(Clazz clazz) {

		List<Double> results = getScores(clazz.hashCode());

		if (results == null) {
			clazz.setRootCauseRating(RanCorrConfiguration.RootCauseRatingFailureState);
			return;
		}

		final double result = correlation(results);

		if (result == errorState) {
			clazz.setRootCauseRating(RanCorrConfiguration.RootCauseRatingFailureState);
			return;
		}

		clazz.setRootCauseRating(mapToPropabilityRange(result));
	}

	/**
	 * This method walks trough all operations and generates the maps required
	 * by the algorithm.
	 *
	 * @param lscp
	 */
	public void generateMaps(final RanCorrLandscape lscp) {
		if (lscp.getOperations() != null) {
			for (CommunicationClazz operation : lscp.getOperations()) {

				Integer target = operation.getTarget().hashCode();
				Integer source = operation.getSource().hashCode();

				// This part writes the anomalyScores to the specified target
				ArrayList<Double> scores = anomalyScores.get(target);
				if (scores != null) {
					scores.addAll(getValuesFromAnomalyList(getAnomalyScores(operation)));
				} else {
					scores = new ArrayList<Double>();
					scores.addAll(getValuesFromAnomalyList(getAnomalyScores(operation)));
				}
				anomalyScores.put(target, scores);

				// This part writes the hash value of the source class to the
				// targets class list
				ArrayList<Integer> sourcesList = sources.get(target);
				if (sourcesList != null) {
					sourcesList.add(source);
				} else {
					sourcesList = new ArrayList<Integer>();
					sourcesList.add(source);
				}
				sources.put(target, sourcesList);

				// This part writes the hash value of the target class to the
				// sources class list
				ArrayList<Integer> targetsList = targets.get(source);
				if (targetsList != null) {
					targetsList.add(target);
				} else {
					targetsList = new ArrayList<Integer>();
					targetsList.add(target);
				}
				targets.put(source, targetsList);

				// This part writes the weight of the connection to the weights
				// list
				Integer weight = weights.get(source + ";" + target);
				if (weight == null) {
					weight = 1;
				}
				weight = weight + operation.getRequests();
				weights.put(source + ";" + target, weight);
			}
		}
	}

	/**
	 * Calculate the Root Cause Ratings of each class with unweightedPowerMeans
	 * to save time in the final correlation phase
	 */
	public void generateRCRs() {
		for (Integer key : anomalyScores.keySet()) {
			RCRs.put(key, Maths.unweightedPowerMean(anomalyScores.get(key), p));
		}
	}

	/**
	 * Returns the Root Cause Rating as described in Marwede et al. Added a
	 * return of the own median if there are no upper or lower dependencies.
	 *
	 * @param results
	 *            List of results generated in {@Link getScores}
	 * @return calculated Root Cause Rating
	 */
	public double correlation(final List<Double> results) {
		if ((results == null) || (results.size() != 3)) {
			return errorState;
		}

		final Double ownMedian = results.get(0);
		final Double inputMedian = results.get(1);
		final Double outputMax = results.get(2);

		if ((inputMedian == errorState) || (outputMax == errorState) || (ownMedian == errorState)) {
			return ownMedian;
		}

		if ((inputMedian > ownMedian) && (outputMax <= ownMedian)) {
			return ((ownMedian + 1) / 2.0);
		} else if ((inputMedian <= ownMedian) && (outputMax > ownMedian)) {
			return ((ownMedian - 1) / 2.0);
		} else {
			return ownMedian;
		}
	}

	/**
	 * Generates the scores required for calculating the Root Cause Rating
	 *
	 * @param clazz
	 *            The hash of the observed Class
	 *
	 * @return List of all required scores to calculate the Root Cause Rating
	 *         First is the own median, second the Input Median, third the Max
	 *         Output Score
	 */
	private List<Double> getScores(Integer clazz) {

		final List<Double> results = new ArrayList<>();

		// The own basic RCR score
		final Double ownMedian = RCRs.get(clazz);
		if (ownMedian == null) {
			results.add(errorState);
		} else {
			results.add(ownMedian);
		}

		// Map used to store the upper Call Relations
		Map<Integer, Record> distanceData = new ConcurrentHashMap<Integer, Record>();

		// List of all checked sources classes
		ArrayList<Integer> finishedCallerClasses = new ArrayList<>();

		ArrayList<Integer> sourcesList = sources.get(clazz);
		if (sourcesList != null) {
			for (Integer source : sourcesList) {
				getInputClasses(source, clazz, 1, 0, distanceData, finishedCallerClasses);
			}
		}
		results.add(getMedianInputScore(distanceData));

		// Default value, kept if no target classes are found
		Double outputScore = errorState;

		// List of all checked target classes
		ArrayList<Integer> finishedCalleeClasses = new ArrayList<>();

		// Run trough all Callees of the observed classes and get the maximum
		// rating
		ArrayList<Integer> targetList = targets.get(clazz);
		if (targetList != null) {
			for (Integer target : targetList) {
				outputScore = getMaxOutputRating(target, outputScore, finishedCalleeClasses);
			}
		}
		results.add(outputScore);

		return results;
	}

	/**
	 * Adds all Callee Classes of the currently observed clazz to the database
	 * trough {@Link addInputClasses}
	 *
	 * @param source
	 *            hash value of the source class
	 * @param target
	 *            hash value of the target class
	 * @param distance
	 *            the current distance
	 * @param weight
	 *            the current weight
	 */
	private void getInputClasses(Integer source, Integer target, Integer distance, Integer weight,
			Map<Integer, Record> distanceData, ArrayList<Integer> finishedCallerClasses) {
		if (!finishedCallerClasses.contains(source)) {
			finishedCallerClasses.add(source);
			Integer addWeight = weights.get(source + ";" + target);
			if (addWeight == null) {
				addWeight = 0;
			}
			weight = weight + addWeight;
			Double RCR = RCRs.get(source);
			if (RCR == null) {
				RCR = errorState;
			}
			addInputClasses(source, weight, RCR, distance, distanceData);
			ArrayList<Integer> sourcesList = sources.get(source);
			if (sourcesList != null) {
				for (Integer nextSource : sourcesList) {
					getInputClasses(nextSource, source, distance + 1, weight, distanceData,
							finishedCallerClasses);
				}
			}
		}
	}

	/**
	 * Adds the given values to the weight/distance data
	 *
	 * @param source
	 *            Hash value of the class that needs to be added
	 * @param weight
	 *            Weight that needs to be added
	 * @param rcr
	 *            RCR that needs to be added
	 * @param distance
	 *            Distance that needs to be added
	 */
	private void addInputClasses(final Integer source, final int weight, final Double rcr,
			final int distance, Map<Integer, Record> distanceData) {
		Record rec = distanceData.get(source);
		if (rec != null) {
			if (rec.distance > distance) {
				rec.distance = distance;
				rec.weight = weight;
				rec.rcr = rcr;
			} else if ((rec.distance == distance) && (rec.weight < weight)) {
				rec.distance = distance;
				rec.weight = weight;
				rec.rcr = rcr;
			}
		} else {
			rec = new Record();
			rec.distance = distance;
			rec.weight = weight;
			rec.rcr = rcr;
		}
		distanceData.put(source, rec);
	}

	/**
	 * Calculating the Callee-related scores as defined in Marwede et al The
	 * values are provided by the Distance Graph generated trough {@Link
	 * getScores}
	 *
	 * @return calculated Median of the input scores
	 */
	private double getMedianInputScore(Map<Integer, Record> distanceData) {
		List<Double> scores = new ArrayList<Double>();
		List<Integer> weights = new ArrayList<Integer>();
		List<Integer> distances = new ArrayList<Integer>();
		for (Integer key : distanceData.keySet()) {
			Record rec = distanceData.get(key);
			scores.add(rec.rcr);
			weights.add(rec.weight);
			distances.add(rec.distance);
		}
		final List<Double> powerWeights = new ArrayList<Double>();
		final List<Double> powerScores = new ArrayList<Double>();

		if (scores.size() == 0) {
			return errorState;
		}

		for (int i = 0; i < scores.size(); i++) {
			if ((scores.get(i) != errorState) && (scores.size() == weights.size())
					&& (scores.size() == distances.size())) {
				powerScores.add(scores.get(i));
				powerWeights.add(weights.get(i) / Math.pow(distances.get(i), z));
			}
		}

		if ((powerScores.size() == 0) || (powerScores.size() != powerWeights.size())) {
			return errorState;
		} else {
			Double result = Maths.weightedPowerMean(powerScores, powerWeights, 1);
			if (result == null) {
				return errorState;
			}
			return result;
		}
	}

	/**
	 * Calculates the maxixum called Root Cause Rating as described in Marwede
	 * et al. It compares the current value to all connected Callees and returns
	 * the highest value.
	 *
	 * @param target
	 *            Hash value of the observed target class
	 * @param max
	 *            The current maximum, errorState if none is found
	 *
	 * @return Maximum Root Cause Rating of all Callees of the observed class or
	 *         the observed class
	 */
	private double getMaxOutputRating(final Integer target, double max,
			ArrayList<Integer> finishedCalleeClasses) {
		if (finishedCalleeClasses.contains(target)) {
			return max;
		} else {
			finishedCalleeClasses.add(target);
			Double newValue = RCRs.get(target);
			if (newValue == null) {
				return max;
			}
			max = Math.max(max, newValue);
			ArrayList<Integer> targetList = targets.get(target);
			if (targetList != null) {
				for (Integer key : targetList) {
					max = Math.max(max, getMaxOutputRating(key, max, finishedCalleeClasses));
				}
			}
			return max;
		}
	}

}
