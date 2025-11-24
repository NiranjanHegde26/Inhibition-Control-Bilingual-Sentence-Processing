(function () {
  var app = angular.module("GermanLEAPQExperimentApp", ["Lingoturk"]);

  app.controller("RenderController", [
    "$http",
    "$timeout",
    "$scope",
    function ($http, $timeout, $scope) {
      var self = this;
      self.state = "";
      self.allStates = [];
      self.questions = [];
      self.part = null;
      self.slideIndex = 0;
      self.questionIndex = 0;
      self.expId = null;
      self.questionId = null;
      self.partId = null;
      self.origin = null;
      self.hitId = "";
      self.assignmentId = "";
      self.workerId = "";
      self.subListMap = {};
      self.subListsIds = [];
      self.showMessage = "none";
      self.redirectUrl = null;

      self.shuffleQuestions = true;
      self.shuffleSublists = true;
      self.useGoodByeMessage = true;
      self.useStatistics = false;
      self.screen1 = true;

      self.form = {
        age: 0,
        gender: "",
        motherTongue: "",
        deCategory: "",
        engCategory: "",
        q1: {
          l1: "",
          l2: "",
          l3: "",
          l4: "",
          l5: "",
        },
        q2: {
          l1: "",
          l2: "",
          l3: "",
          l4: "",
          l5: "",
        },
        q3: {
          l1: 0,
          l2: 0,
          l3: 0,
          l4: 0,
          l5: 0,
        },
        q4: { l1: 0, l2: 0, l3: 0, l4: 0, l5: 0 },
        q5: { l1: 0, l2: 0, l3: 0, l4: 0, l5: 0 },
        // q6: {
        //   id1: {
        //     name: "",
        //     selected: "",
        //   },
        //   id2: {
        //     name: "",
        //     selected: "",
        //   },
        //   id3: {
        //     name: "",
        //     selected: "",
        //   },
        //   id4: {
        //     name: "",
        //     selected: "",
        //   },
        //   id5: {
        //     name: "",
        //     selected: "",
        //   },
        // },
        q7: {
          a: "",
          b: "",
        },
        //q8: 0,
        // q8: {
        //   a: "",
        //   b: "",
        // },
        q9: {
          a: [],
          explained: "",
        },
        // de: {
        //   q1: {
        //     a: 0,
        //     b: 0,
        //     c: 0,
        //     d: 0,
        //   },
        //   q2: {
        //     a: {
        //       year: 0,
        //       month: 0,
        //     },
        //     b: {
        //       year: 0,
        //       month: 0,
        //     },
        //     c: {
        //       year: 0,
        //       month: 0,
        //     },
        //   },
        //   q3: {
        //     speaking: 0,
        //     understanding: 0,
        //     reading: 0,
        //   },
        //   q4: {
        //     friends: "",
        //     family: "",
        //     reading: "",
        //     self_instructions: "",
        //     tv: "",
        //     radio: "",
        //   },
        //   q5: {
        //     friends: "",
        //     family: "",
        //     reading: "",
        //     self_instructions: "",
        //     tv: "",
        //     radio: "",
        //   },
        //   q6: "",
        //   q7: "",
        // },
        eng: {
          q1: {
            a: 0,
            b: 0,
            c: 0,
            d: 0,
          },
          q2: {
            a: {
              year: 0,
              month: 0,
            },
            b: {
              year: 0,
              month: 0,
            },
            c: {
              year: 0,
              month: 0,
            },
          },
          q3: {
            speaking: 0,
            understanding: 0,
            reading: 0,
          },
          q4: {
            friends: "",
            family: "",
            reading: "",
            self_instructions: "",
            tv: "",
            radio: "",
            education: "",
            internet: "",
          },
          q5: {
            friends: "",
            family: "",
            reading: "",
            self_instructions: "",
            tv: "",
            radio: "",
            workplace: "",
            internet: "",
          },
          // q6: "",
          // q7: "",
        },
      };

      self.identification = [
        "0 - keinerlei Zugehörigkeitsgefühl",
        "1 - sehre geringes Zugehörigkeitsgefühl",
        "3",
        "4",
        "5 - mäßiges Zugehörigkeitsgefühl",
        "6",
        "7",
        "8",
        "9",
        "10 - vollständiges Zugehörigkeitsgefühl",
      ];

      self.languageType = [
        "Muttersprache",
        "1. Fremdsprache",
        "2. Fremdsprache",
        "3. Fremdsprache",
        "4. Fremdsprache",
      ];

      self.proficiency_scale = [
        "0 - keine",
        "1 - sehr gering",
        "2 - gering",
        "3 - einigermaßen",
        "4 - etwas schlecter als ausreichend",
        "5 - ausreichend",
        "6 - etwas besser als ausreichend",
        "7 - gut",
        "8 - sehr gut",
        "9 - ausgezeichnet",
        "10 - perfekt",
      ];

      self.contributing_factors = [
        "0 - kein Beitrag",
        "1 - geringfügiger Beitrag",
        "2",
        "3",
        "4",
        "5 - mittelmäßiger Beitrag",
        "6",
        "7",
        "8",
        "9",
        "10 - ausschlaggebender Beitrag",
      ];

      self.exposure = [
        "0 - nie",
        "1 - fast nie",
        "2",
        "3",
        "4",
        "5 - häufig",
        "6",
        "7",
        "8",
        "9",
        "10 - immer",
      ];

      self.accent_perception = [
        "0 - nicht vorhanden",
        "1 - kaum bemerkbar",
        "2 - sehr wenig vorhanden",
        "3 - wenig vorhanden",
        "4 - mäßig vorhanden",
        "5 - merlich vorhanden",
        "6 - deutlich vorhanden",
        "7 - stark",
        "8 - sehr stark",
        "9 - extrem stark",
        "10 - verunstaltend",
      ];

      self.disabilities = [
        "Sehvermögens",
        "Hörvermögens",
        "Sprachvermögens",
        "Lernvermögens",
        "keine Beeinträchtigung",
      ];

      this.toggle = function (dis) {
        let idx = self.form.q9.a.indexOf(dis);
        if (idx > -1) {
          self.form.q9.a.splice(idx, 1); // remove
        } else {
          self.form.q9.a.push(dis); // add
        }
      };

      self.statistics = [
        { name: "Age", type: "number", answer: undefined },
        { name: "Gender", type: "text", answer: "" },
        { name: "Nationality", type: "text", answer: "" },
        { name: "Mother's first language", type: "text", answer: "" },
        { name: "Father's first language", type: "text", answer: "" },
        {
          name: "Are you bilingual (grown up with more than one language)?",
          type: "boolean",
          answer: undefined,
        },
        {
          name: "Please list the languages you speak at at the advance level.",
          type: "text",
          answer: "",
          optional: true,
        },
      ];

      this.resultsSubmitted = function () {
        self.subListsIds.splice(0, 1);
        if (self.subListsIds.length > 0) {
          self.showMessage = "nextSubList";
        } else {
          self.processFinish();
        }
      };

      this.processFinish = function () {
        if (!self.useGoodByeMessage) {
          self.finished();
        } else {
          self.showMessage = "goodBye";
        }
      };

      this.finished = function () {
        if (self.origin == null || self.origin == "NOT AVAILABLE") {
          bootbox.alert(
            "Results successfully submitted. You might consider redirecting your participants now."
          );
        } else if (self.origin == "MTURK") {
          $("#form").submit();
        } else if (self.origin == "PROLIFIC") {
          if (inIframe()) {
            window.top.location.href = self.redirectUrl;
          } else {
            window.location = self.redirectUrl;
          }
        }
      };

      this.nextSublist = function () {
        self.questionIndex = 0;
        self.questions = self.subListMap[self.subListsIds[0]];
        self.showMessage = "none";
      };

      this.resultSubmissionError = function () {
        self.failedTries = 0;
        bootbox.alert(
          "An error occurred while submitting your results. Please try again in a few seconds."
        );
      };

      this.handleError = function () {
        if (self.failedTries < 100) {
          ++self.failedTries;
          setTimeout(function () {
            self.submitResults(self.resultsSubmitted, self.handleError);
          }, 1000);
        } else {
          self.resultSubmissionError();
        }
      };

      self.failedTries = 0;
      this.submitResults = function (successCallback, errorCallback) {
        var results = {
          experimentType: "GermanLEAPQExperiment",
          results: self.questions,
          expId: self.expId,
          origin: self.origin,
          statistics: self.statistics,
          assignmentId: self.assignmentId,
          hitId: self.hitId,
          workerId: self.workerId,
          partId: self.partId == null ? -1 : self.partId,
        };

        $http
          .post("/submitResults", results)
          .success(successCallback)
          .error(errorCallback);
      };

      this.next = function () {
        if (self.state == "workerIdSlide") {
          if (self.questionId == null && self.partId == null) {
            self.load(function () {
              self.state = self.allStates[++self.slideIndex];
            });
            return;
          }
        }

        if (self.slideIndex + 1 < self.allStates.length) {
          self.state = self.allStates[++self.slideIndex];
        } else {
          self.submitResults(self.resultsSubmitted, self.handleError);
        }
      };

      this.checkIdentity = function () {
        let q = self.form.q6;
        for (let id in q) {
          if (q[id]["selected"]) {
            continue;
          }
          if (q[id]["name"].length > 0 && q[id]["selected"].length > 0) {
            continue;
          }
          if (q[id]["name"].length > 0 && q[id]["selected"].length < 1) {
            return true;
          }
          if (q[id]["name"].length < 1 && q[id]["selected"].length > 0) {
            return true;
          }
        }
        return false;
      };

      this.checkInvalidLang = function (questionNumber) {
        let q1 = this.form.q1 || {};
        let q;
        switch (questionNumber) {
          case 3:
            q = self.form.q3 || {};
            break;
          case 4:
            q = self.form.q4 || {};
            break;
          case 5:
            q = self.form.q5 || {};
            break;
          default:
            return false; // invalid question
        }

        for (let i = 1; i <= 5; i++) {
          let lang = q1["l" + i]; // language name from q1
          let perc = q["l" + i]; // percentage for this question
          // case 1: no language but percentage filled
          if (!lang && perc) {
            return true;
          }
          // case 2: language exists but no valid percentage
          if (lang && (!perc || perc < 0 || perc > 100)) {
            return true;
          }
        }
        return false;
      };

      this.getTotal = function (questionNumber) {
        switch (questionNumber) {
          case 3:
            return (
              (parseInt(self.form.q3.l1) || 0) +
              (parseInt(self.form.q3.l2) || 0) +
              (parseInt(self.form.q3.l3) || 0) +
              (parseInt(self.form.q3.l4) || 0) +
              (parseInt(self.form.q3.l5) || 0)
            );
          case 4:
            return (
              (parseInt(self.form.q4.l1) || 0) +
              (parseInt(self.form.q4.l2) || 0) +
              (parseInt(self.form.q4.l3) || 0) +
              (parseInt(self.form.q4.l4) || 0) +
              (parseInt(self.form.q4.l5) || 0)
            );
          case 5:
            return (
              (parseInt(self.form.q5.l1) || 0) +
              (parseInt(self.form.q5.l2) || 0) +
              (parseInt(self.form.q5.l3) || 0) +
              (parseInt(self.form.q5.l4) || 0) +
              (parseInt(self.form.q5.l5) || 0)
            );
          default:
            return false;
        }
      };

      this.validateScreenQuestions = function () {
        if (self.screen1) {
          return this.validateAllScreen1Questions();
        }
        let q = self.screen2 ? self.form.de : self.form.eng; // Based on the screen       // Q1
        if (q.q1.b < 0 || q.q1.c < 0 || q.q1.d < 0) {
          return true;
        }
        // Q2
        if (q.q2.a.month > 12 || q.q2.b.month > 12 || q.q2.c.month > 12) {
          return true;
        }
        if (q.q2.a.year < 0 || q.q2.b.year < 0 || q.q2.c.year < 0) {
          return true;
        }
        // Q3
        if (
          q.q3.reading == "" ||
          q.q3.speaking == "" ||
          q.q3.understanding == ""
        ) {
          return true;
        }
        // Q4
        if (
          q.q4.family == "" ||
          q.q4.friends == "" ||
          q.q4.radio == "" ||
          q.q4.reading == "" ||
          q.q4.self_instructions == "" ||
          q.q4.tv == "" ||
          q.q4.education == "" ||
          q.q4.internet == ""
        ) {
          return true;
        }

        // Q5
        if (
          q.q5.family == "" ||
          q.q5.friends == "" ||
          q.q5.radio == "" ||
          q.q5.reading == "" ||
          q.q5.self_instructions == "" ||
          q.q5.tv == "" ||
          q.q5.internet == "" ||
          q.q5.workplace == ""
        ) {
          return true;
        }

        // Q6 and Q7
        // if (q.q6.length < 1 || q.q7.length < 1) {
        //   return true;
        // }

        return false;
      };

      this.validateAllScreen1Questions = function () {
        // First, check age and gender
        if (self.form.age < 18 || self.form.age > 100) {
          return true;
        }

        if (self.form.gender === "") {
          return true;
        }

        // Languages checks. Atleast English and German should have been there
        if (self.form.q1.l1 === "" && self.form.q1.l2 === "") {
          return true;
        }

        if (self.form.q2.l1 === "" && self.form.q2.l2 === "") {
          return true;
        }

        // Total counts for Q3, Q4, Q5
        if (
          this.getTotal(3) !== 100 ||
          this.getTotal(4) !== 100 ||
          this.getTotal(5) !== 100
        ) {
          return true;
        }

        if (
          this.checkInvalidLang(3) ||
          this.checkInvalidLang(4) ||
          this.checkInvalidLang(5)
        ) {
          return true;
        }

        // Q6
        // if (this.checkIdentity()) {
        //   return true;
        // }

        // Q7
        if (self.form.q7.a > 50 || self.form.q7.a < 1) {
          return true;
        }

        // Q9 (Q8 not mandatory)
        if (self.form.q9.a.length < 1) {
          return true;
        }
        return false;
      };

      this.nextScreen = function () {
        if (self.screen1) {
          //self.screen2 = true;
          self.screen1 = false;
          self.screen3 = true;
          return;
        }
        if (self.screen2) {
          self.screen2 = false;
          self.screen3 = true;
          return;
        }
        if (self.screen3) {
          // All answered
          self.questions[self.questionIndex].answer = self.form; // save Answer
          self.next();
        }
      };

      this.nextQuestion = function () {
        if (self.questionIndex + 1 < self.questions.length) {
          ++self.questionIndex;
        } else {
          self.next();
        }
      };

      this.load = function (callback) {
        var subListMap = self.subListMap;

        if (self.questionId != null) {
          $http.get("/getQuestion/" + self.questionId).success(function (data) {
            self.questions = [data];

            subListMap[self.questions[0].subList] = [self.questions[0]];

            if (callback !== undefined) {
              callback();
            }
          });
        } else if (self.partId != null) {
          $http
            .get("/returnPart?partId=" + self.partId)
            .success(function (data) {
              var json = data;
              self.part = json;
              self.questions = json.questions;

              if (self.shuffleQuestions) {
                shuffleArray(self.part.questions);
              }

              for (var i = 0; i < self.questions.length; ++i) {
                var q = self.questions[i];
                if (subListMap.hasOwnProperty(q.subList)) {
                  subListMap[q.subList].push(q);
                } else {
                  subListMap[q.subList] = [q];
                  self.subListsIds.push(q.subList);
                }
              }
              if (self.shuffleSublists) {
                shuffleArray(self.subListsIds);
              }
              self.questions = self.subListMap[self.subListsIds[0]];

              if (callback !== undefined) {
                callback();
              }
            });
        } else {
          $http
            .get("/getPart?expId=" + self.expId + "&workerId=" + self.workerId)
            .success(function (data) {
              var json = data;
              self.part = json;
              self.partId = json.id;
              self.questions = json.questions;

              if (self.shuffleQuestions) {
                shuffleArray(self.part.questions);
              }

              for (var i = 0; i < self.questions.length; ++i) {
                var q = self.questions[i];
                if (subListMap.hasOwnProperty(q.subList)) {
                  subListMap[q.subList].push(q);
                } else {
                  subListMap[q.subList] = [q];
                  self.subListsIds.push(q.subList);
                }
              }
              if (self.shuffleSublists) {
                shuffleArray(self.subListsIds);
              }
              self.questions = self.subListMap[self.subListsIds[0]];

              if (callback !== undefined) {
                callback();
              }
            });
        }
      };

      $(document).ready(function () {
        self.questionId =
          $("#questionId").length > 0 ? $("#questionId").val() : null;
        self.partId = $("#partId").length > 0 ? $("#partId").val() : null;
        self.expId = $("#expId").length > 0 ? $("#expId").val() : null;
        self.hitId =
          $("#hitId").length > 0 ? $("#hitId").val() : "NOT AVAILABLE";
        self.workerId = $("#workerId").length > 0 ? $("#workerId").val() : "";
        self.assignmentId =
          $("#assignmentId").length > 0
            ? $("#assignmentId").val()
            : "NOT AVAILABLE";
        self.origin =
          $("#origin").length > 0 ? $("#origin").val() : "NOT AVAILABLE";
        self.redirectUrl =
          $("#redirectUrl").length > 0 ? $("#redirectUrl").val() : null;

        if (self.questionId != null || self.partId != null) {
          self.load();
        }

        self.allStates = [
          "instructionsSlide",
          "workerIdSlide",
          "statisticsSlide",
          "questionSlide",
        ];

        if (!self.useStatistics) {
          var index = self.allStates.indexOf("statisticsSlide");
          self.allStates.splice(index, 1);
        }

        if (self.workerId.trim() != "") {
          var index = self.allStates.indexOf("workerIdSlide");
          self.allStates.splice(index, 1);
        }

        $scope.$apply((self.state = self.allStates[0]));

        $(document).on("keypress", ":input:not(textarea)", function (event) {
          if (event.keyCode == 13) {
            event.preventDefault();
          }
        });
      });
    },
  ]);
})();
