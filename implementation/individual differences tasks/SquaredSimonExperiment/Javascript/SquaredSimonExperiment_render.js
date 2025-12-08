(function () {
  var app = angular.module("SquaredSimonExperimentApp", ["Lingoturk"]);

  app.controller("RenderController", [
    "$http",
    "$timeout",
    "$scope",
    "$interval",
    function ($http, $timeout, $scope, $interval) {
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

      self.shuffleQuestions = false;
      self.shuffleSublists = true;
      self.useGoodByeMessage = true;
      self.useStatistics = false;

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

      const rarr = "rarr.PNG";
      const larr = "larr.PNG";

      var stimuli_simon = [
        {
          stim: larr,
          stimsign: "<",
          loc: "left",
          resp1: "LINKS",
          resp2: "RECHTS",
          correctResponse: 0,
          condition: 1,
        },
        {
          stim: rarr,
          stimsign: ">",
          loc: "right",
          resp1: "LINKS",
          resp2: "RECHTS",
          correctResponse: 1,
          condition: 1,
        },
        {
          stim: larr,
          stimsign: "<",
          loc: "left",
          resp1: "RECHTS",
          resp2: "LINKS",
          correctResponse: 1,
          condition: 2,
        },
        {
          stim: rarr,
          stimsign: ">",
          loc: "right",
          resp1: "RECHTS",
          resp2: "LINKS",
          correctResponse: 0,
          condition: 2,
        },
        {
          stim: larr,
          stimsign: "<",
          loc: "right",
          resp1: "LINKS",
          resp2: "RECHTS",
          correctResponse: 0,
          condition: 3,
        },
        {
          stim: rarr,
          stimsign: ">",
          loc: "left",
          resp1: "LINKS",
          resp2: "RECHTS",
          correctResponse: 1,
          condition: 3,
        },
        {
          stim: larr,
          stimsign: "<",
          loc: "right",
          resp1: "RECHTS",
          resp2: "LINKS",
          correctResponse: 1,
          condition: 4,
        },
        {
          stim: rarr,
          stimsign: ">",
          loc: "left",
          resp1: "RECHTS",
          resp2: "LINKS",
          correctResponse: 0,
          condition: 4,
        },
      ];
      self.practiceTrialQuestions = Array(10).fill(stimuli_simon).flat();

      self.practiceQuestionIndex = 0;

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
            "Results successfully submitted. You might consider darkredirecting your participants now."
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
          "An error occurdarkred while submitting your results. Please try again in a few seconds."
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
          experimentType: "SquaredSimonExperiment",
          results: self.questions.filter((q) => q.answer !== undefined),
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
          self.startPracticeCountdown();
          if (self.questionId == null && self.partId == null) {
            self.load(function () {
              self.state = self.allStates[++self.slideIndex];
            });

            return;
          }
        }

        if (self.state === "practiceEndSlide") {
          self.startCountdown();
        }

        if (self.slideIndex + 1 < self.allStates.length) {
          self.state = self.allStates[++self.slideIndex];
        } else {
          self.submitResults(self.resultsSubmitted, self.handleError);
        }
      };

      $scope.practiceTimeLeft = 30;
      var practiceCountdownPromise = null;
      $scope.practiceScore = 0;
      $scope.score = 0;
      $scope.timeLeft = 90;
      var countdownPromise = null;

      this.startPracticeCountdown = function () {
        // Prevent multiple timers
        if (practiceCountdownPromise) return;
        practiceCountdownPromise = $interval(function () {
          if ($scope.practiceTimeLeft > 0) {
            $scope.practiceTimeLeft -= 1;
          } else {
            $interval.cancel(practiceCountdownPromise);
            practiceCountdownPromise = null;
            self.next();
          }
        }, 1000); // runs every 1 second
      };

      // Optional: clean up interval on page change
      $scope.$on("$destroy", function () {
        if (practiceCountdownPromise) {
          $interval.cancel(practiceCountdownPromise);
        }
      });

      this.startCountdown = function () {
        // Prevent multiple timers
        if (countdownPromise) return;
        if (self.questionIndex === 0) {
          self.startTime = Date.now();
        }
        countdownPromise = $interval(function () {
          if ($scope.timeLeft > 0) {
            $scope.timeLeft -= 1;
          } else {
            $interval.cancel(countdownPromise);
            countdownPromise = null;
            self.next();
          }
        }, 1000); // runs every 1 second
      };

      // Optional: clean up interval on page change
      $scope.$on("$destroy", function () {
        if (countdownPromise) {
          $interval.cancel(countdownPromise);
        }
      });

      this.savePracticeAnswer = function (ans) {
        let question = self.practiceTrialQuestions[self.practiceQuestionIndex];
        question.answer = {
          response: ans,
          isCorrect: ans === question.correctResponse,
        };
        $scope.correct = ans === question.correctResponse;
        if ($scope.correct) {
          $scope.practiceScore += 1;
          var delay = 500;
        } else {
          $scope.practiceScore -= 1;
          var delay = 2000; // longer delay for incorrect - to present the reminnder of the task
        }

        $timeout(function () {
          self.nextPracticeQuestion();
        }, delay);
      };

      this.saveAnswer = function (ans) {
        //console.log(ans === parseInt(question.correctResponse));
        let question = self.questions[self.questionIndex];
        question.answer = {
          response: ans,
          isCorrect: ans === parseInt(question.correctResponse),
          RT: Date.now() - self.startTime,
        };
        $scope.correct = ans === parseInt(question.correctResponse);
        if ($scope.correct) {
          $scope.score += 1;
        } else {
          $scope.score -= 1;
        }

        $timeout(function () {
          // Resume the countdown after timeout
          self.nextQuestion();
        }, 500);
      };

      this.nextPracticeQuestion = function () {
        $scope.correct = null;
        if (
          self.practiceQuestionIndex + 1 <
          self.practiceTrialQuestions.length
        ) {
          ++self.practiceQuestionIndex;
        } else {
          self.next();
        }
      };

      this.nextQuestion = function () {
        $scope.correct = null;
        if (self.questionIndex + 1 < self.questions.length) {
          ++self.questionIndex;
          self.startTime = Date.now();
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
          "practiceSlide",
          "practiceEndSlide",
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
