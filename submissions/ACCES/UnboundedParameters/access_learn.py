import coexist
coexist.Access("simulation_script.py").learn(
    num_solutions=10,
    target_sigma=0.1,
    random_seed=42,
)