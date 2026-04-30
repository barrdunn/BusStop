import Foundation

enum MemoryItemsData {

    /// Default Memory Items folder seed used on first launch.
    static let memoryItemsSeed: [MemoryItem] = [
        tawsWarnings,
        lossOfBraking,
        emergencyDescent,
        stallRecovery,
        stallWarningAtLiftOff,
        tcasWarnings,
        unreliableSpeed,
        windshearReactive,
        stabilizedApproach,
    ]

    // MARK: - 1

    static let tawsWarnings = MemoryItem(
        id: "taws-warnings",
        title: "TAWS Warnings",
        callout: "PULL UP TOGA",
        reference: "Refer to Vol II - ABN - SURV - TAWS WARNINGS",
        body: """
        • AP — OFF
        • PITCH — PULL UP
        • THRUST LEVERS — TOGA
        • SPEED BRAKE LEVER — CHECK RETRACTED
        • BANK — WINGS LEVEL or ADJUST
        • DO NOT CHANGE CONFIGURATION (SLATS/FLAP, GEAR) UNTIL CLEAR OF OBSTACLE
        """
    )

    // MARK: - 2

    static let lossOfBraking = MemoryItem(
        id: "loss-of-braking",
        title: "Loss of Braking",
        callout: "LOSS OF BRAKING",
        reference: "Refer to Vol II - ABN - BRAKES - LOSS OF BRAKING",
        body: """
        • REV — MAX
        • BRAKE PEDALS — RELEASE
        • A/SKID OFF — ORDER
        • A/SKID & N/W STRG — OFF
        • BRAKE PEDALS — PRESS
        • MAX BRK PRESS — 1000 PSI

        If still no braking:
        • PARK BRAKE — SHORT SUCCESSIVE APPLICATIONS
        """
    )

    // MARK: - 3

    static let emergencyDescent = MemoryItem(
        id: "emergency-descent",
        title: "Emergency Descent",
        callout: "EMERGENCY DESCENT",
        reference: "Refer to Vol II - ABN - MISC - EMERGENCY DESCENT",
        body: """
        • CREW OXY MASKS — USE
        • SIGNS — ON
        • EMER DESCENT — INITIATE

        If A/THR is not active:
          • THR LEVERS — IDLE

        • SPD BRK — FULL
        """
    )

    // MARK: - 4

    static let stallRecovery = MemoryItem(
        id: "stall-recovery",
        title: "Stall Recovery",
        callout: "STALL, I HAVE CONTROL",
        reference: "Refer to Vol II - ABN - MISC - STALL RECOVERY",
        body: """
        • NOSE DOWN PITCH CONTROL — APPLY
        • BANK — WINGS LEVEL

        When out of Stall (no longer stall indications):
        • THRUST — INCREASE SMOOTHLY AS NEEDED
        • SPEEDBRAKES — CHECK RETRACTED
        • FLIGHT PATH — RECOVER SMOOTHLY

        If in clean configuration and below 20,000 feet:
        • FLAP 1 — SELECT
        """
    )

    // MARK: - 5

    static let stallWarningAtLiftOff = MemoryItem(
        id: "stall-warning-liftoff",
        title: "Stall Warning at Lift-Off",
        callout: "STALL, TOGA 15 DEGREES",
        reference: "Refer to Vol II - ABN - MISC - STALL WARNING AT LIFTOFF",
        body: """
        • THRUST — TOGA

        At the same time:
        • PITCH ATTITUDE — 15°
        • BANK — WINGS LEVEL
        """
    )

    // MARK: - 6

    static let tcasWarnings = MemoryItem(
        id: "tcas-warnings",
        title: "TCAS Warnings – Resolution Advisory",
        callout: "TCAS BLUE",
        reference: "Refer to Vol II - ABN - SURV - TCAS WARNINGS - RESOLUTION ADVISORY",
        body: """
        "TCAS BLUE" (AP/FD TCAS Installed)
        • If the AP is OFF
          - FD ORDERS — FOLLOW
          - The AP can be engaged
        • VERTICAL SPEED — MONITOR

        "TCAS, I HAVE CONTROL" (NO TCAS FMA)
        • AP (if engaged) — OFF
        • BOTH FD's — OFF
          - Respond promptly and smoothly
        • VERTICAL SPEED — ADJUST OR MAINTAIN
          - Adjust or maintain the vertical speed as required to reach the green area and/or avoid the red area of the vertical speed scale
        """
    )

    // MARK: - 7

    static let unreliableSpeed = MemoryItem(
        id: "unreliable-speed",
        title: "Unreliable Speed Indication",
        callout: "UNRELIABLE AIRSPEED",
        reference: "Refer to Vol II - ABN - NAV - [MEM] UNRELIABLE SPEED INDICATION",
        body: """
        If the safe conduct of flight is impacted:
        • AP/FD — OFF
        • A/THR — OFF
        • THRUST/PITCH
          - Below THR RED ALT — 15°/TOGA
          - Above THR RED ALT & below FL100 — 10°/CL
          - Above THR RED ALT & above FL100 — 5°/CL
        • FLAPS — MAINTAIN CURRENT CONFIG
        • FLAPS (IF CONF FULL) — SELECT 3 AND MAINTAIN
        • SPEEDBRAKES — CHECK RETRACTED
        • L/G — UP
        • When at or above MSA or Circuit Altitude: Level off for troubleshooting
        """
    )

    // MARK: - 8

    static let windshearReactive = MemoryItem(
        id: "windshear-reactive",
        title: "Windshear – Reactive",
        callout: "WINDSHEAR TOGA",
        reference: "Refer to Vol II - ABN - SURV - [MEM] WINDSHEAR WARNING - REACTIVE WINDSHEAR",
        body: """
        At Takeoff - Before V1:
        • If significant variations in airspeed and trend below indicated V1, REJECT THE TAKEOFF

        At Takeoff - After V1:
        • THR LEVERS — TOGA
        • REACHING Vʀ — ROTATE
        • SRS ORDERS — FOLLOW
          - This includes full back stick if demanded.

        Airborne, initial climb or landing:
        • THR LEVERS AT TOGA — SET OR CONFIRM
        • AP (if engaged) — KEEP ON
        • SRS ORDERS — FOLLOW
        • DO NOT CHANGE CONFIGURATION (SLATS/FLAPS, GEAR) UNTIL OUT OF WINDSHEAR
        • CAREFULLY MONITOR FLIGHT PATH AND SPEED
        • WHEN OUT, SMOOTHLY RECOVER NORMAL CLIMB
        """
    )

    // MARK: - Extras

    static let stabilizedApproach = MemoryItem(
        id: "stabilized-approach",
        title: "Stabilized Approach Criteria",
        callout: "STABILIZED APPROACH",
        reference: "Refer to Vol II - OPERATING LIMITATIONS",
        body: """
        By 1000 ft AFE:
        • Rate of descent not to exceed 1,200 FPM
        • On correct lateral path ("Course") — ± one dot for ILS/LOC, 0.30 NM cross track for RNAV, or 1/2 dot for VOR*
        • On correct vertical path ("Glidepath") — ± one dot*
        • In final landing configuration — Landing Gear and Flaps Extended, Speed Brakes Retracted
        • Absent any GPWS Warnings and Cautions

        By 500 ft AFE (all of the above, plus):
        • Landing Checklist Completed
        • Rate of descent not to exceed 1,000 FPM
        • Within -5 to +15 knots of target speed for approach
        • Thrust stabilized, usually above idle, commensurate with what is required to maintain the target speed criteria
        """
    )
}
