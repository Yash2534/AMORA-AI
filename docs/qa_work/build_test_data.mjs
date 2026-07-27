import fs from "node:fs/promises";
import path from "node:path";
import {
  SpreadsheetFile,
  Workbook,
} from "@oai/artifact-tool";

const root = path.resolve("D:/Projects/amora_ai");
const workDir = path.join(root, "docs", "qa_work");
const data = JSON.parse(
  await fs.readFile(path.join(workDir, "qa_dataset.json"), "utf8"),
);
const outputPath = path.join(
  root,
  "docs",
  "Amora_QA_Testing_Report_Test_Data.xlsx",
);
const previewDir = path.join(workDir, "xlsx_previews");
await fs.mkdir(previewDir, { recursive: true });

const colors = {
  primary: "#3D0B3F",
  secondary: "#EC5FA8",
  tertiary: "#F4A9CE",
  background: "#FDF1F7",
  surface: "#FFFFFF",
  text: "#2B2B2B",
};

const workbook = Workbook.create();
const dashboard = workbook.worksheets.add("Dashboard");
const testCases = workbook.worksheets.add("Test Cases");
const rtm = workbook.worksheets.add("RTM");
const defects = workbook.worksheets.add("Defects");
const risks = workbook.worksheets.add("Risks");
const modules = workbook.worksheets.add("Module Summary");
const environment = workbook.worksheets.add("Environment");
const builds = workbook.worksheets.add("Build Results");
const safeData = workbook.worksheets.add("Safe Test Data");
const evidence = workbook.worksheets.add("Evidence Index");

for (const sheet of workbook.worksheets.items) {
  sheet.showGridLines = false;
}

function styleTitle(sheet, range, title, subtitle = "") {
  range.merge();
  range.values = [[title]];
  range.format = {
    fill: colors.primary,
    font: { bold: true, color: colors.surface, fontSize: 20 },
    verticalAlignment: "center",
    horizontalAlignment: "left",
  };
  range.format.rowHeight = 34;
  if (subtitle) {
    const row = Number(range.address.match(/\d+/)?.[0] ?? 1) + 1;
    const subtitleRange = sheet.getRange(`A${row}:O${row}`);
    subtitleRange.merge();
    subtitleRange.values = [[subtitle]];
    subtitleRange.format = {
      fill: colors.background,
      font: { color: colors.text, italic: true, fontSize: 10 },
      verticalAlignment: "center",
    };
    subtitleRange.format.rowHeight = 24;
  }
}

function styleHeader(range) {
  range.format = {
    fill: colors.primary,
    font: { bold: true, color: colors.surface, fontSize: 10 },
    wrapText: true,
    verticalAlignment: "center",
    horizontalAlignment: "left",
    borders: {
      bottom: { style: "medium", color: colors.secondary },
    },
  };
  range.format.rowHeight = 30;
}

function addLightBorders(range) {
  range.format.borders = {
    insideHorizontal: { style: "thin", color: colors.tertiary },
    bottom: { style: "thin", color: colors.tertiary },
  };
}

// Test catalogue.
const caseHeaders = [
  "Test Case ID",
  "Module",
  "Test Scenario",
  "Test Objective",
  "Preconditions",
  "Test Data",
  "Execution Steps",
  "Expected Result",
  "Actual Result",
  "Status",
  "Priority",
  "Severity if Failed",
  "Environment",
  "Evidence Reference",
  "Remarks",
];
testCases.getRange("A1:O1").values = [caseHeaders];
testCases.getRange(`A2:O${data.cases.length + 1}`).values = data.cases.map(
  (item) => [
    item.id,
    item.module,
    item.scenario,
    item.objective,
    item.preconditions,
    item.test_data,
    item.steps,
    item.expected,
    item.actual,
    item.status,
    item.priority,
    item.severity,
    item.environment,
    item.evidence,
    item.remarks,
  ],
);
styleHeader(testCases.getRange("A1:O1"));
const testBody = testCases.getRange(`A2:O${data.cases.length + 1}`);
testBody.format = {
  font: { color: colors.text, fontSize: 9 },
  wrapText: true,
  verticalAlignment: "top",
};
addLightBorders(testBody);
testCases.freezePanes.freezeRows(1);
testCases.freezePanes.freezeColumns(2);
const widths = [14, 19, 32, 31, 28, 24, 42, 31, 34, 14, 12, 14, 27, 21, 28];
widths.forEach((width, index) => {
  testCases.getRangeByIndexes(0, index, data.cases.length + 1, 1).format.columnWidth =
    width;
});
testCases.getRange(`J2:J${data.cases.length + 1}`).dataValidation = {
  rule: {
    type: "list",
    values: ["Pass", "Fail", "Blocked", "Not Run", "Not Applicable"],
  },
};
testCases.getRange(`K2:K${data.cases.length + 1}`).dataValidation = {
  rule: {
    type: "list",
    values: ["Critical", "High", "Medium", "Low"],
  },
};
testCases.getRange(`L2:L${data.cases.length + 1}`).dataValidation = {
  rule: { type: "list", values: ["", "P0", "P1", "P2", "P3", "P4"] },
};
const statusRange = testCases.getRange(`J2:J${data.cases.length + 1}`);
for (const [textValue, fill, font] of [
  ["Pass", colors.background, colors.primary],
  ["Fail", colors.secondary, colors.surface],
  ["Blocked", colors.tertiary, colors.primary],
  ["Not Run", colors.surface, colors.text],
  ["Not Applicable", colors.surface, colors.text],
]) {
  statusRange.conditionalFormats.add("containsText", {
    text: textValue,
    format: { fill, font: { color: font, bold: true } },
  });
}

// Dashboard with live formulas.
styleTitle(
  dashboard,
  dashboard.getRange("A1:N1"),
  "AMORA QA TESTING SCORECARD",
  "Submission-ready QA status derived from the editable Test Cases sheet",
);
dashboard.getRange("A4:N4").values = [[
  "Catalogue",
  "",
  "Pass",
  "",
  "Fail",
  "",
  "Blocked",
  "",
  "Not Run",
  "",
  "N/A",
  "",
  "Executed Pass %",
  "",
]];
dashboard.getRange("A4:N4").format = {
  fill: colors.tertiary,
  font: { bold: true, color: colors.primary, fontSize: 10 },
  horizontalAlignment: "center",
};
dashboard.getRange("A5:N7").format = {
  fill: colors.surface,
  font: { bold: true, color: colors.primary, fontSize: 20 },
  horizontalAlignment: "center",
  verticalAlignment: "center",
  borders: { preset: "outside", style: "thin", color: colors.tertiary },
};
for (const range of ["A5:B7", "C5:D7", "E5:F7", "G5:H7", "I5:J7", "K5:L7", "M5:N7"]) {
  dashboard.getRange(range).merge();
}
dashboard.getRange("A5").formulas = [[`=COUNTA('Test Cases'!A2:A181)`]];
dashboard.getRange("C5").formulas = [[`=COUNTIF('Test Cases'!J2:J181,"Pass")`]];
dashboard.getRange("E5").formulas = [[`=COUNTIF('Test Cases'!J2:J181,"Fail")`]];
dashboard.getRange("G5").formulas = [[`=COUNTIF('Test Cases'!J2:J181,"Blocked")`]];
dashboard.getRange("I5").formulas = [[`=COUNTIF('Test Cases'!J2:J181,"Not Run")`]];
dashboard.getRange("K5").formulas = [[`=COUNTIF('Test Cases'!J2:J181,"Not Applicable")`]];
dashboard.getRange("M5").formulas = [[
  `=IFERROR(C5/(C5+E5),0)`,
]];
dashboard.getRange("M5").format.numberFormat = "0.0%";
dashboard.getRange("A9:F9").values = [[
  "Release decision",
  "Automated suite",
  "Analyzer",
  "Web build",
  "Debug APK",
  "Confirmed defects",
]];
styleHeader(dashboard.getRange("A9:F9"));
dashboard.getRange("A10:F10").values = [[
  data.metadata.release_decision,
  `${data.metadata.automated_passed} pass / ${data.metadata.automated_failed} fail / ${data.metadata.automated_skipped} skipped`,
  "PASS",
  "PASS",
  "PASS",
  data.metadata.confirmed_defects,
]];
dashboard.getRange("A10:F10").format = {
  fill: colors.background,
  font: { bold: true, color: colors.text },
  wrapText: true,
  verticalAlignment: "center",
};
dashboard.getRange("A10:F10").format.rowHeight = 40;
dashboard.getRange("A13:B18").values = [
  ["Status", "Count"],
  ["Pass", null],
  ["Fail", null],
  ["Blocked", null],
  ["Not Run", null],
  ["Not Applicable", null],
];
styleHeader(dashboard.getRange("A13:B13"));
dashboard.getRange("B14:B18").formulas = [
  ["=C5"],
  ["=E5"],
  ["=G5"],
  ["=I5"],
  ["=K5"],
];
dashboard.getRange("A14:B18").format = {
  fill: colors.surface,
  font: { color: colors.text },
};
addLightBorders(dashboard.getRange("A14:B18"));
const statusChart = dashboard.charts.add(
  "bar",
  dashboard.getRange("A13:B18"),
);
statusChart.title = "Catalogue status distribution";
statusChart.hasLegend = false;
if (statusChart.series.items.length > 0) {
  statusChart.series.items[0].fill = colors.secondary;
}
statusChart.setPosition("D13", "J29");
dashboard.getRange("L13:N17").values = [
  ["Metric", "Observed", "Interpretation"],
  ["APK size", "164.3 MiB", "Optimization required"],
  ["Web output", "64.9 MiB", "Build succeeded"],
  ["Routes", "93 constants", "Large prototype surface"],
  ["Backend SDK", "None", "Production blocker"],
];
styleHeader(dashboard.getRange("L13:N13"));
dashboard.getRange("L14:N17").format = {
  fill: colors.background,
  font: { color: colors.text, fontSize: 10 },
  wrapText: true,
};
addLightBorders(dashboard.getRange("L14:N17"));
dashboard.getRange("A31:N34").merge();
dashboard.getRange("A31").values = [[
  "Decision rationale: analyzer, web compilation and debug APK succeeded, but the "
    + "complete automated suite fails, production backend/payment/auth integrations "
    + "are absent, demo OTP behavior is exposed, and Android release identity/signing "
    + "is not production-ready. Release decision: NOT READY.",
]];
dashboard.getRange("A31:N34").format = {
  fill: colors.primary,
  font: { color: colors.surface, bold: true, fontSize: 12 },
  wrapText: true,
  verticalAlignment: "center",
};
dashboard.getRange("A:N").format.columnWidth = 13;
dashboard.freezePanes.freezeRows(2);

// RTM.
const rtmHeaders = [
  "Requirement ID",
  "Module",
  "Requirement",
  "Source",
  "Test Case IDs",
  "Priority",
  "Implementation Status",
  "Test Status",
  "Remarks",
];
rtm.getRange("A1:I1").values = [rtmHeaders];
rtm.getRange(`A2:I${data.requirements.length + 1}`).values =
  data.requirements.map((item) => [
    item.id,
    item.module,
    item.requirement,
    item.source,
    item.test_cases,
    item.priority,
    item.implementation,
    item.test_status,
    item.remarks,
  ]);
styleHeader(rtm.getRange("A1:I1"));
rtm.getRange(`A2:I${data.requirements.length + 1}`).format = {
  font: { color: colors.text, fontSize: 9 },
  wrapText: true,
  verticalAlignment: "top",
};
addLightBorders(rtm.getRange(`A2:I${data.requirements.length + 1}`));
[16, 20, 42, 24, 32, 12, 22, 28, 28].forEach((width, index) => {
  rtm.getRangeByIndexes(0, index, data.requirements.length + 1, 1).format.columnWidth =
    width;
});
rtm.freezePanes.freezeRows(1);

// Defects.
const defectHeaders = [
  "Defect ID",
  "Module",
  "Title",
  "Description",
  "Steps to Reproduce",
  "Expected Result",
  "Actual Result",
  "Severity",
  "Priority",
  "Status",
  "Evidence",
  "Recommended Fix",
];
defects.getRange("A1:L1").values = [defectHeaders];
defects.getRange(`A2:L${data.defects.length + 1}`).values =
  data.defects.map((item) => [
    item.id,
    item.module,
    item.title,
    item.description,
    item.steps,
    item.expected,
    item.actual,
    item.severity,
    item.priority,
    item.status,
    item.evidence,
    item.fix,
  ]);
styleHeader(defects.getRange("A1:L1"));
defects.getRange(`A2:L${data.defects.length + 1}`).format = {
  font: { color: colors.text, fontSize: 9 },
  wrapText: true,
  verticalAlignment: "top",
};
addLightBorders(defects.getRange(`A2:L${data.defects.length + 1}`));
[14, 18, 32, 36, 32, 30, 32, 10, 12, 12, 18, 40].forEach(
  (width, index) => {
    defects.getRangeByIndexes(0, index, data.defects.length + 1, 1).format.columnWidth =
      width;
  },
);
defects.freezePanes.freezeRows(1);

// Risks.
const riskHeaders = [
  "Risk ID",
  "Risk",
  "Probability",
  "Impact",
  "Risk Level",
  "Affected Module",
  "Mitigation",
  "Owner",
  "Status",
];
risks.getRange("A1:I1").values = [riskHeaders];
risks.getRange(`A2:I${data.risks.length + 1}`).values = data.risks.map(
  (item) => [
    item.id,
    item.risk,
    item.probability,
    item.impact,
    item.level,
    item.module,
    item.mitigation,
    item.owner,
    item.status,
  ],
);
styleHeader(risks.getRange("A1:I1"));
risks.getRange(`A2:I${data.risks.length + 1}`).format = {
  font: { color: colors.text, fontSize: 9 },
  wrapText: true,
  verticalAlignment: "top",
};
addLightBorders(risks.getRange(`A2:I${data.risks.length + 1}`));
[14, 42, 13, 13, 13, 22, 42, 16, 12].forEach((width, index) => {
  risks.getRangeByIndexes(0, index, data.risks.length + 1, 1).format.columnWidth =
    width;
});
risks.freezePanes.freezeRows(1);

// Module summary with formulas linked to Test Cases.
const moduleNames = Object.keys(data.module_summary);
modules.getRange("A1:G1").values = [[
  "Module",
  "Total",
  "Pass",
  "Fail",
  "Blocked",
  "Not Run",
  "N/A",
]];
styleHeader(modules.getRange("A1:G1"));
modules.getRange(`A2:A${moduleNames.length + 1}`).values = moduleNames.map(
  (name) => [name],
);
for (let row = 2; row <= moduleNames.length + 1; row++) {
  modules.getRange(`B${row}`).formulas = [[
    `=COUNTIF('Test Cases'!$B$2:$B$181,A${row})`,
  ]];
  modules.getRange(`C${row}`).formulas = [[
    `=COUNTIFS('Test Cases'!$B$2:$B$181,A${row},'Test Cases'!$J$2:$J$181,"Pass")`,
  ]];
  modules.getRange(`D${row}`).formulas = [[
    `=COUNTIFS('Test Cases'!$B$2:$B$181,A${row},'Test Cases'!$J$2:$J$181,"Fail")`,
  ]];
  modules.getRange(`E${row}`).formulas = [[
    `=COUNTIFS('Test Cases'!$B$2:$B$181,A${row},'Test Cases'!$J$2:$J$181,"Blocked")`,
  ]];
  modules.getRange(`F${row}`).formulas = [[
    `=COUNTIFS('Test Cases'!$B$2:$B$181,A${row},'Test Cases'!$J$2:$J$181,"Not Run")`,
  ]];
  modules.getRange(`G${row}`).formulas = [[
    `=COUNTIFS('Test Cases'!$B$2:$B$181,A${row},'Test Cases'!$J$2:$J$181,"Not Applicable")`,
  ]];
}
modules.getRange(`A2:G${moduleNames.length + 1}`).format = {
  fill: colors.surface,
  font: { color: colors.text, fontSize: 10 },
};
addLightBorders(modules.getRange(`A2:G${moduleNames.length + 1}`));
modules.getRange("A:A").format.columnWidth = 28;
modules.getRange("B:G").format.columnWidth = 13;
modules.freezePanes.freezeRows(1);

// Environment.
const environmentRows = [
  ["Property", "Observed Value", "QA Interpretation"],
  ["OS", "Windows 11 Home Single Language 64-bit, 25H2", "Executed host"],
  ["Flutter", "3.44.6 stable", "Analyzer/tests/builds executed"],
  ["Dart", "3.12.2", "Formatter/tests executed"],
  ["Android SDK", "36.1.0; platform/build-tools 36.1.0", "Debug build target"],
  ["APK SDK levels", "minSdk 24; targetSdk 36", "Read from built APK"],
  ["Java", "OpenJDK 21.0.8 via Android Studio", "Gradle runtime"],
  ["Chrome", "150.0.7871.182", "Debug launch target"],
  ["Connected Android", "None", "Physical-device cases blocked"],
  ["Windows desktop", "Toolchain incomplete", "Not a validated release target"],
  ["Backend", "No production SDK/config declared", "Frontend prototype"],
  ["Build mode", "Web release build; Android debug APK", "Both succeeded"],
  ["Internet", "Flutter doctor network check passed", "Dependency resolution available"],
  ["Test account", "Local fictional fixtures", "No production account"],
  ["IDE", "Android Studio detected; Codex desktop QA workflow", "No IDE claim beyond detection"],
];
environment.getRange(`A1:C${environmentRows.length}`).values = environmentRows;
styleHeader(environment.getRange("A1:C1"));
environment.getRange(`A2:C${environmentRows.length}`).format = {
  font: { color: colors.text, fontSize: 10 },
  wrapText: true,
  verticalAlignment: "top",
};
addLightBorders(environment.getRange(`A2:C${environmentRows.length}`));
environment.getRange("A:A").format.columnWidth = 24;
environment.getRange("B:B").format.columnWidth = 44;
environment.getRange("C:C").format.columnWidth = 38;

// Build results.
const buildRows = [
  ["Command", "Result", "Duration", "Output / Warning"],
  ["flutter clean", "Pass", "3.8 s", "Generated output removed"],
  ["flutter pub get", "Pass", "4.5 s", "4 newer incompatible package versions noted"],
  ["dart format lib", "Pass", "3.23 s", "137 files; 0 changed"],
  ["flutter analyze", "Pass", "3.0 s", "No issues found"],
  ["flutter test", "Fail", "Full run", "115 pass; 23 fail; 5 skipped"],
  ["flutter build web", "Pass", "81.7 s", "build/web; 68,034,713 bytes"],
  ["flutter run -d chrome", "Started", "50.3 s", "Debug service connected; manual control not completed"],
  ["flutter build apk --debug", "Pass", "54.5 s", "app-debug.apk; 172,299,833 bytes"],
  ["flutter build apk --release", "Not Attempted", "—", "Debug signing/template ID; unsafe to claim release readiness"],
];
builds.getRange(`A1:D${buildRows.length}`).values = buildRows;
styleHeader(builds.getRange("A1:D1"));
builds.getRange(`A2:D${buildRows.length}`).format = {
  font: { color: colors.text, fontSize: 10 },
  wrapText: true,
  verticalAlignment: "top",
};
addLightBorders(builds.getRange(`A2:D${buildRows.length}`));
[32, 16, 15, 62].forEach((width, index) => {
  builds.getRangeByIndexes(0, index, buildRows.length, 1).format.columnWidth =
    width;
});

// Safe data.
safeData.getRange("A1:C1").values = [["Field", "Safe Value", "Handling Rule"]];
styleHeader(safeData.getRange("A1:C1"));
const safeRows = Object.entries(data.safe_test_data).map(([key, value]) => [
  key.replaceAll("_", " "),
  value,
  ["password", "otp"].includes(key)
    ? "Never record real values."
    : "Fictional/local only.",
]);
safeData.getRange(`A2:C${safeRows.length + 1}`).values = safeRows;
safeData.getRange(`A2:C${safeRows.length + 1}`).format = {
  fill: colors.background,
  font: { color: colors.text, fontSize: 10 },
  wrapText: true,
};
addLightBorders(safeData.getRange(`A2:C${safeRows.length + 1}`));
safeData.getRange("A:A").format.columnWidth = 24;
safeData.getRange("B:B").format.columnWidth = 52;
safeData.getRange("C:C").format.columnWidth = 34;

// Evidence index.
const evidenceRows = [
  ["Evidence ID", "Artifact", "Purpose"],
  ["EV-UI-001", "EV-UI-001_auth_mobile.png", "Authentication mobile render"],
  ["EV-UI-002", "EV-UI-002_discover_mobile.png", "Discover mobile render"],
  ["EV-UI-003", "EV-UI-003_events_mobile.png", "Events mobile render"],
  ["EV-UI-004", "EV-UI-004_event_detail_mobile.png", "Event detail mobile render"],
  ["EV-UI-005", "EV-UI-005_profile_mobile.png", "Profile mobile render"],
  ["EV-UI-006", "EV-UI-006_faq_support_mobile.png", "Email-only FAQ Support render"],
  ["EV-UI-007", "EV-UI-007_events_desktop.png", "Events desktop render"],
  ["EV-BUILD-001", "EV-BUILD-001_build_and_environment.txt", "Commands, environment and outputs"],
  ["EV-TEST-001", "EV-TEST-001_test_run_summary.txt", "Automated results and failure families"],
  ["EV-SOURCE-001", "EV-SOURCE-001_project_inventory.txt", "Architecture/dependency inventory"],
  ["EV-LIMIT-001", "EV-LIMIT-001_test_limitations.txt", "Explicit non-claims and blockers"],
];
evidence.getRange(`A1:C${evidenceRows.length}`).values = evidenceRows;
styleHeader(evidence.getRange("A1:C1"));
evidence.getRange(`A2:C${evidenceRows.length}`).format = {
  font: { color: colors.text, fontSize: 10 },
  wrapText: true,
};
addLightBorders(evidence.getRange(`A2:C${evidenceRows.length}`));
evidence.getRange("A:A").format.columnWidth = 18;
evidence.getRange("B:B").format.columnWidth = 52;
evidence.getRange("C:C").format.columnWidth = 48;

// Workbook verification and previews.
const summaryInspect = await workbook.inspect({
  kind: "sheet,table",
  maxChars: 8000,
  tableMaxRows: 4,
  tableMaxCols: 8,
});
await fs.writeFile(
  path.join(workDir, "xlsx_inspect_summary.txt"),
  summaryInspect.ndjson ?? String(summaryInspect),
  "utf8",
);
const formulaInspect = await workbook.inspect({
  kind: "formula",
  sheetId: "Dashboard",
  range: "A1:N35",
  maxChars: 6000,
});
await fs.writeFile(
  path.join(workDir, "xlsx_formula_audit.txt"),
  formulaInspect.ndjson ?? String(formulaInspect),
  "utf8",
);

for (const sheetName of [
  "Dashboard",
  "RTM",
  "Defects",
  "Risks",
  "Module Summary",
  "Environment",
  "Build Results",
  "Safe Test Data",
  "Evidence Index",
]) {
  const preview = await workbook.render({
    sheetName,
    autoCrop: "all",
    scale: 1,
    format: "png",
  });
  await fs.writeFile(
    path.join(previewDir, `${sheetName.replaceAll(" ", "_")}.png`),
    new Uint8Array(await preview.arrayBuffer()),
  );
}
const cataloguePreview = await workbook.render({
  sheetName: "Test Cases",
  range: "A1:O14",
  scale: 0.8,
  format: "png",
});
await fs.writeFile(
  path.join(previewDir, "Test_Cases_sample.png"),
  new Uint8Array(await cataloguePreview.arrayBuffer()),
);

const output = await SpreadsheetFile.exportXlsx(workbook);
await output.save(outputPath);
console.log(outputPath);
