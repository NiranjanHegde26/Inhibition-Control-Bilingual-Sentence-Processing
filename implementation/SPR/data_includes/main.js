// Author: Niranjana Hegde BS
// First Iteration Date: 27/09/2025
//Inspired by https://chuprinko-kirill.github.io/pcibex_tutorial/sprt.html and https://pryslopska.com/projects/lab_crab/pcibex/questionnaire/

PennController.ResetPrefix(null); // Shorten command names (keep this line here))
DebugOff(); // Uncomment this line only when you are 100% done designing your experiment
var showProgressBar = false;
// First show instructions, then experiment trials, send results and show end screen
Sequence(
  "counter",
  "instructions",
  "prolific_id",
  "spr_instructions",
  randomize("practice"),
  "practice_end",
  randomize("experiment"),
  SendResults(),
  "end"
);
SetCounter("counter", "inc", 1);

Header(newVar("USER").global()).log("user_id", getVar("USER")); // Capture Prolific-ID and retain it for the trials

PennController(
  "instructions",
  newHtml("instructions", "instructions.html")
    .checkboxWarning(
      "Bitte stimmen Sie der Einwilligung zu, indem Sie das Kästchen ankreuzen."
    )
    .center()
    .print(),
  // this is required to actually display the content. Otherwise the element exists, but isn't visible
  newButton("next", "Weiter")
    .css({
      "margin-top": "20px",
      padding: "6px 15px",
      "font-size": "14px",
      "font-weight": "400",
      "line-height": "1.42857143",
      "text-align": "center",
      "white-space": "nowrap",
      "vertical-align": "middle",
      "-ms-touch-action": "manipulation",
      "touch-action": "manipulation",
      cursor: "pointer",
      "-webkit-user-select": "none",
      "-moz-user-select": "none",
      "-ms-user-select": "none",
      "user-select": "none",
      "background-image": "none",
      border: "1px solid transparent",
      "border-radius": "4px",
    })
    .print()
    .center()
    .wait(
      getHtml("instructions")
        .test.complete()
        .failure(getHtml("instructions").warn())
    )
  // wait() in general means that the element doesn't progress till a certain action is executed
);

newTrial(
  "prolific_id",
  defaultText.center().print(),
  newText(
    "participant_info_header",
    "<p><b>Bitte geben Sie Ihre Prolific-ID ein.</b></p>"
  ).css({ "font-size": "16px", margin: "10em 0 0 0" }),
  newText("participantID", "Prolific-ID*").print(),
  newTextInput("input_ID")
    .css({ margin: "2em 0 2em 2em" })
    .center()
    .log()
    .print(),
  newButton("next", "Weiter")
    .css({
      "margin-top": "20px",
      padding: "6px 12px",
      "margin-left": "1em",
      "font-size": "14px",
      "font-weight": "400",
      "line-height": "1.42857143",
      "text-align": "center",
      "white-space": "nowrap",
      "vertical-align": "middle",
      "-ms-touch-action": "manipulation",
      "touch-action": "manipulation",
      cursor: "pointer",
      "-webkit-user-select": "none",
      "-moz-user-select": "none",
      "-ms-user-select": "none",
      "user-select": "none",
      "background-image": "none",
      border: "1px solid transparent",
      "border-radius": "4px",
    })
    .center()
    .print()
    // Check whether Prolific-ID is entered
    .wait(
      newFunction("dummy", () => true)
        .test.is(true)
        // ID
        .and(getTextInput("input_ID").testNot.text(""))
    ),
  getVar("USER").set(getTextInput("input_ID"))
);

PennController(
  "spr_instructions",
  newHtml("spr_instructions", "spr_instructions.html").center().print(), // this is required to actually display the content. Otherwise the element exists, but isn't visible
  newButton("Next")
    .css({
      "margin-top": "20px",
      padding: "6px 12px",
      "font-size": "14px",
      "font-weight": "400",
      "line-height": "1.42857143",
      "text-align": "center",
      "white-space": "nowrap",
      "vertical-align": "middle",
      "-ms-touch-action": "manipulation",
      "touch-action": "manipulation",
      cursor: "pointer",
      "-webkit-user-select": "none",
      "-moz-user-select": "none",
      "-ms-user-select": "none",
      "user-select": "none",
      "background-image": "none",
      border: "1px solid transparent",
      "border-radius": "4px",
    })
    .bold()
    .center()
    .print()
    .wait()
);

Template("practice.csv", (row) =>
  // This allows us to follow the same template for each row of a provided csv file
  newTrial(
    "practice",
    newText("insSpace", "Press Space Bar to start the sentence")
      .cssContainer({
        "font-family": "serif",
        "font-size": "19px",
        "padding-top": "50px",
        "line-height": "400%",
      })
      .italic()
      .center()
      .print("center at 50vw", "middle at 40vh"),

    newKey(" ").wait(),

    getText("insSpace").remove(),

    newController("DashedSentence", {
      s: row.Sentence,
      mode: "self-paced reading",
      hideUnderscores: true,
    })
      .cssContainer({
        "font-family": "monospace",
        "font-size": "15px",
        margin: "200px 150px 80px 0px",
        width: "1200px",
      })
      .print()
      .wait()
      .remove(),

    newFunction("test_quest", () => row.Question == "")
      .testNot.is()
      .failure(
        newText("question-sentence", row.Question)
          .cssContainer({
            "margin-bottom": "0em",
            "font-weight": "bold",
            "font-size": "20px",
          })
          .center()
          .print("center at 50vw", "middle at 37vh"),
        newText("question-sentence", "Press D for 'Yes' and K for 'No'")
          .cssContainer({
            "margin-bottom": "0em",
            "font-weight": "bold",
            "font-size": "15px",
          })
          .center()
          .print("center at 50vw", "middle at 42vh"),
        newScale("answer-practice", "Yes", "No")
          .css("font-size", "1.5em", "center")
          .center()
          .button()
          .keys("D", "K")
          .css({ gap: "60px" })
          .print("center at 50vw", "middle at 50vh")
          .wait(),

        getScale("answer-practice")
          .test.selected(row.Answer)
          .success(
            newText("feedback", "Right Answer")
              .cssContainer({ "font-size": "20px" })
              .color("green")
              .print("center at 50vw", "middle at 25vh")
          )
          .failure(
            newText("feedback", "Wrong Answer")
              .cssContainer({ "font-size": "20px" })
              .color("red")
              .print("center at 50vw", "middle at 25vh")
          ),
        newTimer("pause", 1000) // Brief pause to see feedback
          .start()
          .wait()
      )
  )
);

PennController(
  "practice_end",
  newHtml("practice_end", "practice_end.html").center().print(),
  newButton("Next")
    .css({
      "margin-top": "20px",
      padding: "6px 12px",
      "font-size": "14px",
      "font-weight": "400",
      "line-height": "1.42857143",
      "text-align": "center",
      "white-space": "nowrap",
      "vertical-align": "middle",
      "-ms-touch-action": "manipulation",
      "touch-action": "manipulation",
      cursor: "pointer",
      "-webkit-user-select": "none",
      "-moz-user-select": "none",
      "-ms-user-select": "none",
      "user-select": "none",
      "background-image": "none",
      border: "1px solid transparent",
      "border-radius": "4px",
    })
    .bold()
    .center("center at 50vw", "middle at 40vh")
    .print()
    .wait()
);

Template(
  "main.csv",
  (row) =>
    newTrial(
      "experiment",
      newText("insSpace", "Press Space Bar to start the sentence")
        .cssContainer({
          "font-family": "serif",
          "font-size": "19px",
          "padding-top": "50px",
          "line-height": "400%",
        })
        .italic()
        .center()
        .print("center at 50vw", "middle at 40vh"),

      newKey(" ").wait(),

      getText("insSpace") // With get text, we can make modifications to prior elements. Here, it is removed, because the same element contains multiple text elements that will appear at the same spot.
        .remove(),

      newController("DashedSentence", {
        s: row.Sentence,
        mode: "self-paced reading",
        hideUnderscores: true,
      })
        .cssContainer({
          "font-family": "monospace",
          "font-size": "15px",
          margin: "200px 150px 80px 0px",
          width: "1200px",
        })
        .print()
        .log()
        .wait()
        .remove(),

      newFunction("test_quest", () => row.Question == "")
        .testNot.is()
        .failure(
          newText("question-sentence", row.Question)
            .cssContainer({
              "margin-bottom": "0em",
              "font-weight": "bold",
              "font-size": "20px",
            })
            .center()
            .print("center at 50vw", "middle at 37vh"),
          newText("question-sentence", "Press D for 'Yes' and K for 'No'")
            .cssContainer({
              "margin-bottom": "0em",
              "font-weight": "bold",
              "font-size": "15px",
            })
            .center()
            .print("center at 50vw", "middle at 42vh"),
          newScale("answer-practice", "Yes", "No")
            .css("font-size", "1.5em", "center")
            .center()
            .button()
            .keys("D", "K")
            .css({ gap: "60px" })
            .log()
            .print("center at 50vw", "middle at 50vh")
            .wait()
        )
    )
      .log("SentenceID", row.SentenceID) // Or the column you want to retain
      .log("ItemID", row.ItemID) // Or the column you want to retain
      .log("Condition", row.Condition) // Or the column you want to retain
);

PennController(
  "end",
  newHtml("end", "end.html").center().print(), // this is required to actually display the content. Otherwise the element exists, but isn't visible
  newButton("Next")
    .css({
      "margin-top": "20px",
      padding: "6px 12px",
      "font-size": "14px",
      "font-weight": "400",
      "line-height": "1.42857143",
      "text-align": "center",
      "white-space": "nowrap",
      "vertical-align": "middle",
      "-ms-touch-action": "manipulation",
      "touch-action": "manipulation",
      cursor: "pointer",
      "-webkit-user-select": "none",
      "-moz-user-select": "none",
      "-ms-user-select": "none",
      "user-select": "none",
      "background-image": "none",
      border: "1px solid transparent",
      "border-radius": "4px",
    })
    .bold()
    .center()
    .print()
    .wait() // wait() in general means that the element doesn't progress till a certain action is executed
);
