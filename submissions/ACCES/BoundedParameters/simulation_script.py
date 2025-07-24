# ACCES PARAMETERS START
import coexist
import subprocess

def create_parameters(**kw):
    variables = list(kw.keys())
    minimums = [kw[v][0] for v in variables]
    maximums = [kw[v][1] for v in variables]
    values = [kw[v][2] if len(kw[v]) == 3 else (kw[v][0] + kw[v][1]) / 2 for v in variables]
    return coexist.create_parameters(variables, minimums, maximums, values)

parameters = create_parameters(**{
    "orography_scale": (0, 2, 1.1225500464800942),
    "mountain_height": (-2000, 5000, 220.31392224420077),
    "mountain_size": (0, 30, 12.017635114),
    "mountain_lon": (-180, 180, -15.841509987790861),
    "mountain_lat": (-90, 90, -86.12422836923388),
    "temperature_equator": (270, 300, 288.90809710269053),
    "temperature_pole": (270, 300, 298.96513672809175),
    "temperature_usa": (-5, 5, 4.925009771675318),
    "temperature_pa": (-5, 5, 3.5009899916848117),
    "zonal_wind": (5, 50, 6.871195942673129),
})
# ACCES PARAMETERS END


print("[Python]\n", parameters.value, "\n")
proc = subprocess.run(
    ["julia", "--project=.", "simulate_rain_simple.jl",
     " ".join(map(str, parameters.value.to_numpy()))],
    check=True,
    capture_output=True,
)

output = proc.stdout.decode()
print("[Julia]\n", output)

precipitation = float(output.split()[-1])
print(f"[Python]\nMaximum precipitation (mm): {precipitation}")

error = -precipitation
