#include "setapply.h"
#include "powerstate.h"
#include <stdlib.h>
#include <string.h>

int set_cpu(POWER_STATE power_state, LEGIOND_CONFIG *config)
{
	if (config->cpu_control == 0) {
		printf("cpu_control is set to false\n");
		printf("skip cpu_control\n");
		return 0;
	}

	const char *cmd;
	switch (power_state) {
	case P_AC_Q:
		cmd = config->cpu_ac_q;
		break;
	case P_BAT_Q:
		cmd = config->cpu_bat_q;
		break;
	case P_AC_B:
		cmd = config->cpu_ac_b;
		break;
	case P_BAT_B:
		cmd = config->cpu_bat_b;
		break;
	case P_AC_BP:
		cmd = config->cpu_ac_bp;
		break;
	case P_BAT_BP:
		cmd = config->cpu_bat_bp;
		break;
	case P_AC_P:
		cmd = config->cpu_ac_p;
		break;
	case P_BAT_P:
		cmd = config->cpu_bat_p;
		break;
	default:
		cmd = NULL;
		break;
	}

	int result = 0;

	if (cmd != NULL && cmd[0] != '\0') {
		result = system(cmd);
	} else {
		printf("set_cpu: unknown power state, skipping\n");
		return 1;
	}

	if (result != 0) {
		printf("cpu_control cmd failed\n");
	} else {
		printf("cpu_control cmd started\n");
	}

	return result;
}

int set_fancurve(POWER_STATE power_state, LEGIOND_CONFIG *config)
{
	if (config->fan_control == 0) {
		printf("fan_control is set to false\n");
		printf("skip fan_control\n");
		return 0;
	}

	char cmd[100] = "legion_cli fancurve-write-preset-to-hw ";
	switch (power_state) {
	case P_AC_Q:
		strcat(cmd, "quiet-ac");
		break;
	case P_BAT_Q:
		strcat(cmd, "quiet-battery");
		break;
	case P_AC_B:
		strcat(cmd, "balanced-ac");
		break;
	case P_BAT_B:
		strcat(cmd, "balanced-battery");
		break;
	case P_AC_BP:
		strcat(cmd, "balanced-performance-ac");
		break;
	case P_BAT_BP:
		strcat(cmd, "balanced-performance-battery");
		break;
	case P_AC_P:
		strcat(cmd, "performance-ac");
		break;
	case P_BAT_P:
		strcat(cmd, "performance-battery");
		break;
	default:
		cmd[0] = '\0';
		break;
	}

	int result = 0;

	if (cmd[0] != '\0') {
		result = system(cmd);
	} else {
		printf("set_fancurve: unknown power state, skipping\n");
		return 1;
	}

	if (result != 0) {
		printf("fancurve_control cmd failed\n");
	} else {
		printf("fancurve_control cmd started\n");
	}

	return result;
}

int set_gpu(POWER_STATE power_state, LEGIOND_CONFIG *config)
{
	if (strcmp(config->gpu_control, "false") == 0) {
		printf("gpu_control is set to false\n");
		printf("skip gpu_control\n");
		return 0;
	}
	char cmd[256] = { 0 };
	if (strcmp(config->gpu_control, "nvidia") == 0) {
		snprintf(cmd, sizeof(cmd), "/opt/bin/nvidia-smi -pl ");
	} else if (strcmp(config->gpu_control, "radeon") == 0) {
		snprintf(cmd, sizeof(cmd),
			 "/opt/bin/rocm-smi --setpoweroverdrive ");
	} else {
		printf("gpu_control: unknown gpu type '%s'\n",
		       config->gpu_control);
		return 0;
	}

	const char *tdp = NULL;
	switch (power_state) {
	case P_AC_Q:
		tdp = config->gpu_tdp_ac_q;
		break;
	case P_BAT_Q:
		tdp = config->gpu_tdp_bat_q;
		break;
	case P_AC_B:
		tdp = config->gpu_tdp_ac_b;
		break;
	case P_BAT_B:
		tdp = config->gpu_tdp_bat_b;
		break;
	case P_AC_BP:
		tdp = config->gpu_tdp_ac_bp;
		break;
	case P_BAT_BP:
		tdp = config->gpu_tdp_bat_bp;
		break;
	case P_AC_P:
		tdp = config->gpu_tdp_ac_p;
		break;
	case P_BAT_P:
		tdp = config->gpu_tdp_bat_p;
		break;
	default:
		tdp = NULL;
		break;
	}

	if (tdp == NULL || tdp[0] == '\0') {
		printf("set_gpu: unknown power state, skipping\n");
		return 1;
	}

	size_t len = strlen(cmd);
	snprintf(cmd + len, sizeof(cmd) - len, "%s", tdp);

	int result = 0;

	if (cmd[0] != '\0') {
		result = system(cmd);
	}

	if (result != 0) {
		printf("gpu_control cmd failed\n");
	} else {
		printf("gpu_control cmd started\n");
	}

	return result;
}

int set_all(POWER_STATE power_state, LEGIOND_CONFIG *config)
{
	set_fancurve(power_state, config);
	set_cpu(power_state, config);
	set_gpu(power_state, config);
	return 0;
}
