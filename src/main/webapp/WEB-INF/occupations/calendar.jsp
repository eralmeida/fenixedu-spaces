<!DOCTYPE html>

<%@ taglib prefix="spring" uri="http://www.springframework.org/tags" %>


<head>
	<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
	<spring:url var="staticUrl" value="/static/fenix-spaces"/>
	
	
	<link href="${staticUrl}/css/fullcalendar.css" rel="stylesheet">
	<link href="${staticUrl}/css/fullcalendar.print.css" rel="stylesheet" media="print">
	<link rel="stylesheet" href="${staticUrl}/css/jquery.datetimepicker.css">
		
	<!-- <link href="./libs/bootstrap/dist/css/bootstrap.css" rel="stylesheet"> -->
	
	<!--  <script src="./libs/jquery/jquery.min.js"></script>--> 
	<script src="${staticUrl}/js/jquery-ui.min.js"></script>
	<script src="${staticUrl}/js/fullcalendar.min.js"></script>
	<script src="${staticUrl}/js/moment.min.js"></script>
	<script src="${staticUrl}/js/dateutils.js"></script>
	<script src="${staticUrl}/js/jquery.datetimepicker.js"></script>
	<script src="${staticUrl}/js/sprintf.min.js"></script>
</head>

<script>

	var date = new Date();
	var d = date.getDate();
	var m = date.getMonth();
	var y = date.getFullYear();
	
	var calendar = {
		header: {
			left: 'prev,next today',
			center: 'title',
			right: 'agendaWeek,month,year'
		},
		monthNames: ['Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho', 'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'],
		monthNamesShort: ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'],
		dayNames: dayNames,
		dayNamesShort: dayNamesShort,
		buttonText: {
   			today:    'Hoje',
   			month:    'Mês',
   			week:     'Semana',
   			day:      'Ano'
		},
		timeFormat: { month: 'H:mm{ - H:mm}', '' : "H:mm" } ,
		columnFormat : {
   					month: 'ddd',    // Mon
   					week: 'ddd d/M', // Mon 9/7
   					day: 'dddd d/M'  // Monday 9/7
		},
		minTime : "08:00",
		maxTime : "24:00",
		axisFormat: 'H:mm',
		allDaySlot : false,
		editable: true,
		defaultView: "agendaWeek",
		firstDay: 1,
		editable: false,
		eventClick : function(event, jsEvent, view) {
			editEvent(event)
		}
	};

	var occupationEvents = {}
	var indexOccupationEvents = 1;

	function toggleCreator(state) {
		return function() {
			this.checked = state;
		}
	};

	var selectCheckbox = toggleCreator(true);
	var unselectCheckbox = toggleCreator(false);
	
	function weeklyClearAll() {
		$("#weekdays input").each(unselectCheckbox);
	}
	
	function nthDayOfTheWeekLabel(when) {
		var nth = nthdayOfTheWeek(when)
		if (nth > 3) {
			return "<spring:message code="calendar.dayofweek.last" text="Último"/>";
		}
		var first = "<spring:message code="calendar.dayofweek.first" text="primeira"/>";
		var second = "<spring:message code="calendar.dayofweek.second" text="segunda"/>";
		var third = "<spring:message code="calendar.dayofweek.third" text="terceira"/>";
		var fourth = "<spring:message code="calendar.dayofweek.fourth" text="quarta"/>";
		
		var labels = [first, second, third, fourth];
		return labels[nth];
	}
	
	function dayOfWeekLabel(when) {
		var dayOfWeek = when.isoWeekday();
		return dayNames[dayOfWeek];
	};

	var repeatsconfig = {
		"w": {
			init: function() {
				var that = this;
	
				function selectDays(selector) {
					return function() {
						weeklyClearAll();
						if (selector) {
							$(selector).each(selectCheckbox);
						}
						that.updateSummary();
					}
				}
				$(".repeats").show();
	
				$("#weekdays input").click(function() {
					that.updateSummary();
				});
	
				$("#weekly-all").click(selectDays("#weekdays input"));
				$("#weekly-tue-thu").click(selectDays("#weekdays #tu,#weekdays #th"));
				$("#weekly-mon-wed-fri").click(selectDays("#weekdays #mo,#weekdays #we,#weekdays #fr"));
				$("#weekly-clear").click(selectDays());
			},
			html: "#weeklyrepeatson",
			label: "<spring:message code="calendar.repeatson.weekly" text="Semanas"/>",
			summary: "<spring:message code="calendar.repeats.weekly" text="Semanalmente"/>",
			updateSummary: function() {
				var selectedDays = []
				$("#weekdays input").each(function() {
					if (this.checked) {
						selectedDays.push($(this).attr('title'))
					}
				});
				var label = this['summary'];
				if (selectedDays.length > 0) {
					label += " <spring:message code="calendar.on" text="às"/> " + selectedDays.join(", ")
				}
				$("#summary").html(label)
			},
			processIntervals: function() {
				var occupation = this.getOccupation();
				var end = occupation.end
				var when = occupation.start.clone();
				var weekly = occupation.repeatsevery
				var weekdays = occupation.weekdays();
				var adjustWhen = function() {
					var found = 0
					$(weekdays).each(function(i, e) {
						if (e === when.isoWeekday()) {
							found = i;
							return false;
						}
					});
					var weekday = weekdays[found];
					when.isoWeekday(weekday)
					if (when.isBefore(occupation.start)) {
						when.add('weeks', 1)
					}
					return found;
				}
				var whenIndex = adjustWhen();
				var intervals = [];
				var i = whenIndex;
				while (when.isBefore(end) || when.isSame(end)) {
					var iStart = when.clone();
					var iEnd = when.clone();
					if (occupation.isAllDay) {
						iEnd.add('days', 1)						
					} else {
						iEnd.hour(end.hour());
						iEnd.minute(end.minute());	
					}
					intervals.push({
						start: iStart,
						end: iEnd
					});
					if (i === weekdays.length - 1) {
						i = 0;
						when.add('weeks', 1);
					} else {
						i++;
					}
					var weekday = weekdays[i];
					when.isoWeekday(weekday);
				}
				return intervals;
			},
			getOccupation: function() {
				return {
					start: getStartMoment(),
					end: getEndMoment(),
					isAllDay: isAllDay(),
					repeatsevery: $("#repeatsevery").val(),
					frequency: $("#frequency").val(),
					weekdays : function() {
						var dict = { "mo" : 1, "tu" : 2, "we": 3 , "th" : 4 , "fr" : 5, "sa" : 6, "su": 7};
						return $("#weekdays input").filter(function() {
							return $(this).prop("checked");
						}).map(function() {
							return this.id;
						}).map(function() {
							return dict[this];
						}).get();
					},
				}
			}
		},
	
		"d": {
			init: function() {
				$(".repeats").show();
			},
			html: undefined,
			label: "<spring:message code="calendar.repeatson.days" text="Dias"/>",
			summary: "<spring:message code="calendar.repeats.daily" text="Diariamente"/>",
			processIntervals: function() {
				var occupation = this.getOccupation();
				var start = occupation.start
				var end = occupation.end
				var daily = occupation.repeatsevery
				var when = start.clone();
				var intervals = [];
				while (when.isBefore(end) || when.isSame(end)) {
					var iStart = when.clone();
					var iEnd = when.clone();
					if (occupation.isAllDay) {
						iEnd.add('days', 1)
					} else {
						iEnd.hour(end.hour());
						iEnd.minute(end.minute());
					}
					intervals.push({
						start: iStart,
						end: iEnd
					});
					when.add('days', daily);
				}
				return intervals;
			},
			getOccupation: function() {
				return {
					start: getStartMoment(),
					end: getEndMoment(),
					isAllDay: isAllDay(),
					repeatsevery: $("#repeatsevery").val(),
					frequency: $("#frequency").val(),
				}
			}
		},
	
		"m": {
			init: function() {
				$(".repeats").show();
				var self = this;
				$("input:radio[name=monthly]").click(function() {
					self.updateSummary();
				})
			},
			html: "#monthlyrepeatson",
			label: "<spring:message code="calendar.repeatson.monthly" text="Meses"/>",
			summary: "<spring:message code="calendar.repeats.monthly" text="Mensalmente"/>",
			updateSummary: function() {
				var startdate = moment($("#startdate").val(), "DD/MM/YYYY")
				var value = $("input:radio[name=monthly]:checked").val();
				if (value == "dayofmonth") {
					$("#summary").html(this["summary"] + "<spring:message code="calendar.repeatson.summary.dayofmonth" text=" ao dia "/>" + startdate.date());
				}
				if (value == "dayofweek") {
					$("#summary").html(this["summary"] + "<spring:message code="calendar.repeatson.summary.dayofweek" text=" à "/>" + nthDayOfTheWeekLabel(startdate) + " " + dayOfWeekLabel(startdate));
				}
			},
			getOccupation: function() {
				return {
					start: getStartMoment(),
					end: getEndMoment(),
					isAllDay: isAllDay(),
					repeatsevery: $("#repeatsevery").val(),
					monthlyType: $("input:radio[name=monthly]:checked").val(),
					frequency: $("#frequency").val()
				}
			},
			dayOfMonth : function(start, end, isAllDay, monthly) {
				var when = start.clone();
				var intervals = [];
				while (when.isBefore(end) || when.isSame(end)) {
					var iStart = when.clone();
					var iEnd = when.clone();
					if (isAllDay) {
						iEnd.add('days', 1)						
					} else {
						iEnd.hour(end.hour());
						iEnd.minute(end.minute());	
					}
					intervals.push({
						start: iStart,
						end: iEnd
					});
					when.add('months', monthly);
				}
				return intervals;
			},
			dayOfWeek : function(start, end, isAllDay, monthly) {
				var nthDayOfWeek = nthdayOfTheWeek(start);
				var when = start.clone();
				var dayOfWeek = when.isoWeekday();
				var intervals = [];
				while (when.isBefore(end) || when.isSame(end)) {
					var iStart = when.clone();
					var iEnd = when.clone();
					if (isAllDay) {
						iEnd.add('days', 1)						
					} else {
						iEnd.hour(end.hour());
						iEnd.minute(end.minute());	
					}
					intervals.push({
						start: iStart,
						end: iEnd
					});
					when.add('months', monthly)
					when = getNextNthdayOfWeek(when, nthDayOfWeek, dayOfWeek)
				}
				return intervals;
	
			},
			processIntervals: function() {
				var occupation = this.getOccupation();
				var start = occupation.start
				var end = occupation.end
				var isAllDay = occupation.isAllDay
				var monthly = occupation.repeatsevery
				if (occupation.monthlyType == "dayofmonth") {
					return this.dayOfMonth(start, end, isAllDay, monthly);
				}
				if (occupation.monthlyType == "dayofweek") {
					return this.dayOfWeek(start, end, isAllDay, monthly);
				}
			}
		},
	
		"n": {
			init: function() {
				$(".repeats").hide();
			},
			html: undefined,
			label: undefined,
			summary: "<spring:message code="calendar.repeats.never" text="Nunca"/>",
			getOccupation: function() {
				return {
					start: getStartMoment(),
					end: getEndMoment(),
					isAllDay: isAllDay(),
					repeatsevery: undefined,
					frequency: $("#frequency").val()
				}
			},
			processIntervals: function() {
				var occupation = this.getOccupation();
				var start = occupation.start
				var end = occupation.end
				var intervals = [];
				var start = occupation.start
				var end = occupation.end
				intervals.push({ start : start, end: end})
				return intervals;
			}
		},
	
		"y": {
			init: function() {
				$(".repeats").show();
			},
			html: undefined,
			label: "<spring:message code="calendar.repeatson.yearly" text="Anos"/>",
			summary: "<spring:message code="calendar.repeats.yearly" text="Anualmente"/>",
			getOccupation: function() {
				return {
					start: getStartMoment(),
					end: getEndMoment(),
					isAllDay: isAllDay(),
					repeatsevery: $("#repeatsevery").val(),
					frequency: $("#frequency").val()
				}
			},
			processIntervals: function() {
				var occupation = this.getOccupation();
				var start = occupation.start
				var end = occupation.end
				var yearly = occupation.repeatsevery
				var when = start.clone();
				var intervals = [];
				while (when.isBefore(end) || when.isSame(end)) {
					var iStart = when.clone();
					var iEnd = when.clone();
					if (occupation.isAllDay) {
						iEnd.add('days', 1)						
					} else {
						iEnd.hour(end.hour());
						iEnd.minute(end.minute());	
					}
					intervals.push({
						start: iStart,
						end: iEnd
					});
					when.add('years', yearly);
				}
				return intervals;
			}
		}
	};

	function addEvent(interval, occupation) {
		var occupationEvent = {
				id : occupation.id,
				allDay: false,
				start: interval.start.format("X"),
				end: interval.end.format("X")
		};
		$('#calendar').fullCalendar('renderEvent', occupationEvent, true);
	}
	
	function editEvent(calendarEvent) {
		var event = occupationEvents[calendarEvent.id];
		$("#startdate").val(event.start.format("DD/MM/YYYY"));
		$("#enddate").val(event.end.format("DD/MM/YYYY"));
		if (event.isAllDay) {
			if (!$("#allday").prop("checked")) {
				$("#allday").click();
			}
		} else {
			$("#starttime").val(event.start.format("HH:mm"));
			$("#endtime").val(event.end.format("HH:mm"));
		}
		$("#repeatsevery").val(event.repeatsevery)
		$("#frequency").val(event.frequency);
		$("#myModal").data("event", calendarEvent.id);
		$("#delete").show();
		$("#myModal").modal("show");
	}
	
	/*function gotoFirstEvent() {
		var events = $("#calendar").fullCalendar('clientEvents');
		var event = events[0]
		
		var year = moment(event.start).year();
		var month = moment(event.start).month();
		var day = moment(event.start).date();
		$("#calendar").fullCalendar('gotoDate', year, month, day);
	}*/

	$(document).ready(function() {
		
		$('#calendar').fullCalendar(calendar);

		var datepickerConfig = { format : "d/m/Y", 
				  mask: true, 
				  timepicker : false,
				  value : moment().format("DD/MM/YYYY"),
				  onSelectDate: function(current,$input){
				  					var config = repeatsconfig[$("#frequency").val()];
				  					if (config.updateSummary) {
				  						config.updateSummary();
				  					}
								}
				};

		$("#startdate").datetimepicker(datepickerConfig);

		datepickerConfig.value = null;

		$("#enddate").datetimepicker(datepickerConfig);


		var timepickerConfig = { format : "H:i", mask: true, datepicker : false, step:30};

		$("#starttime,#endtime").datetimepicker(timepickerConfig);

		$("#add-event").click(function() {
			$("#delete").hide();
			$("#myModal").modal("show");
		});

		$(".repeats").hide();

		$("#allday").change(function() {
			if (this.checked) {
				$("#starttime").hide();
				$("#endtime").hide();
			}else {
				$("#starttime").show();
				$("#endtime").show();
			}
		});

		$("#frequency").change(function() {
			var val = $(this).val();
			$("#repeatsconfig").empty();
			var config = repeatsconfig[val];
			var html = config['html'];
			var label = config['label'];
			var summary = config['summary'];
			if (html) {
				$("#repeatsconfig").html($(html).html())	
			}
			if (label) {
				$("#repeatsevery-label").html(label);
			}
			if (summary) {
				$("#summary").html(summary);
			}
			config.init();
		});

		// init repeatsevery options
		for (var i = 1; i <= 30; i++) {
			$("#repeatsevery").append(sprintf("<option value='%1$s'>%1$s</option>", i));
		}

		$("#save").click(function() {
			var event_id = $("#myModal").data("event")
			var config = repeatsconfig[$("#frequency").val()];
			var occupation = config.getOccupation();
			
			if (!isNaN(event_id)) {
				$("#calendar").fullCalendar('removeEvents', event_id)
				occupation.id = event_id;
			} else {
				occupation.id = indexOccupationEvents++;
			}

			occupationEvents[occupation.id] = occupation;
			$(config.processIntervals()).each(function() {
				addEvent(this, occupation);
			});

			$("#myModal").removeData("event")
			$("#myModal").modal("hide")
			$("#add-event").attr("disabled",true)
		});

		$("#delete").click(function() {
			var event_id = $("#myModal").data("event");
			delete occupationEvents[event_id];
			$("#calendar").fullCalendar('removeEvents', event_id);
			$("#myModal").modal('hide');
			$("#add-event").attr("disabled",false)
		});

		/** init code **/
		$("#frequency option[value=w]").prop('selected', true);
		$("#repeatsevery option[value=1]").select();
		$("#frequency").change();
		$("#mo, #we").click();
		$("#delete").hide();
	});
</script>
	
<script type="text/html" id="weeklyrepeatson">
<th class="col-lg-3"><spring:message code="calendar.repeatson" text="Repete em"/></th>
<td class="col-lg-9">
	<span id="weekdays">
		<input id="mo" type="checkbox" title="<spring:message code="calendar.daysofweek.mo" text="Segunda-Feira"/>">
		<span title="<spring:message code="calendar.daysofweek.mo" text="Segunda-Feira"/>"><spring:message code="calendar.daysofweek.short.mo" text="S"/></span>
		<input id="tu" type="checkbox" title="<spring:message code="calendar.daysofweek.tu" text="Terça-Feira"/>">
		<span title="<spring:message code="calendar.daysofweek.tu" text="Terça-Feira"/>"><spring:message code="calendar.daysofweek.short.tu" text="T"/></span>
		<input id="we" type="checkbox" title="<spring:message code="calendar.daysofweek.we" text="Quarta-Feira"/>">
		<span title="<spring:message code="calendar.daysofweek.we" text="Quarta-Feira"/>"><spring:message code="calendar.daysofweek.short.we" text="Q"/></span>
		<input id="th" type="checkbox" title="<spring:message code="calendar.daysofweek.th" text="Quinta-Feira"/>">
		<span title="<spring:message code="calendar.daysofweek.th" text="Quinta-Feira"/>"><spring:message code="calendar.daysofweek.short.th" text="Q"/></span>
		<input id="fr" type="checkbox" title="<spring:message code="calendar.daysofweek.fr" text="Sexta-Feira"/>">
		<span title="<spring:message code="calendar.daysofweek.fr" text="Sexta-Feira"/>"><spring:message code="calendar.daysofweek.short.fr" text="S"/></span>
		<input id="sa" type="checkbox" title="<spring:message code="calendar.daysofweek.sa" text="Sábado"/>">
		<span title="<spring:message code="calendar.daysofweek.sa" text="Sábado"/>"><spring:message code="calendar.daysofweek.short.sa" text="S"/></span>
		<input id="su" type="checkbox" title="<spring:message code="calendar.daysofweek.su" text="Domingo"/>">
		<span title="<spring:message code="calendar.daysofweek.su" text="Domingo"/>"><spring:message code="calendar.daysofweek.short.su" text="D"/></span>
	</span>
	<span style="display: block;">
		<button class="btn btn-xs btn-success" id="weekly-all"><spring:message code="calendar.all" text="Todos"/></button>
		<button class="btn btn-xs btn-success" id="weekly-tue-thu">3 e 5</button>
		<button class="btn btn-xs btn-success" id="weekly-mon-wed-fri">2,4 e 6</button>
		<button class="btn btn-xs btn-success" id="weekly-clear"><spring:message code="calendar.clear" text="Limpar"/></button>
	</span>
</td>			
</script>

<script type="text/html" id="monthlyrepeatson">
<th class="col-lg-3">Repeat by</th>
<td class="col-lg-9">
	<span id="options">
		<input type="radio" name="monthly" value="dayofmonth" checked/>
		<span><spring:message code="calendar.repeatson.montly.dayofmonth" text="Dia do Mês"/></span>
		<input type="radio" name="monthly" value="dayofweek"/>
		<span><spring:message code="calendar.repeatson.montly.dayofweek" text="Dia da Semana"/></span>
	</span>
</td>			
</script>

<style>
#myModal {
	text-align: center;
}
</style>


<body>
	<div id="calendar"></div>
	<span>
		<!-- Button trigger modal -->
		<button class="btn btn-primary" id="add-event">
			<spring:message code="calendar.add.event" text="Seleccionar Período"/>
		</button>
	</span>

	<!-- Modal -->
	<div class="modal fade" id="myModal" tabindex="-1" role="dialog" aria-labelledby="myModalLabel" aria-hidden="true">
  		<div class="modal-dialog">
			<div class="modal-content">
				<div class="modal-header">
		        	<button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>
		        	<h4 class="modal-title" id="myModalLabel"><spring:message code="calendar.add.event" text="Seleccionar Período"/></h4>
		      	</div>
				<div class="modal-body">
		        	<table class="table" id="create-event">
						<tr class="row">
							<th class="col-lg-3"><spring:message code="calendar.start" text="Início"/></th>
							<td>
								<span style="display:block;">
									<input type="text" id="startdate"/>
								</span>
							</td>
						</tr>
						<tr class="row">
							<th class="col-lg-3"><spring:message code="calendar.end" text="Fim"/></th>
							<td class="col-lg-9">
								
								<span style="display:block;">
									<input type="text" id="enddate"/>
								</span>
								
							</td>
						</tr>
						<tr class="row">
							<th class="col-lg-3"><spring:message code="calendar.repeatsevery" text="Todo o dia"/></th>
							<td class="col-lg-9">
								<input type="checkbox" id="allday"/>
								<span style="display:block;">
										<input type="text" id="starttime"/>
									</span>
									<span>
										<input type="text" id="endtime"/>
									</span>
								</td>
							</tr>
							<tr class="row">
								<th class="col-lg-3"><spring:message code="calendar.repeats" text="Repete"/></th>
								<td class="col-lg-9">
									<select id="frequency">
										<option value="n"><spring:message code="calendar.repeats.never" text="Nunca"/></option>
										<option value="d"><spring:message code="calendar.repeats.daily" text="Diariamente"/></option>
										<option value="w"><spring:message code="calendar.repeats.weekly" text="Semanalmente"/></option>
										<option value="m"><spring:message code="calendar.repeats.monthly" text="Mensalmente"/></option>
										<option value="y"><spring:message code="calendar.repeats.yearly" text="Anualmente"/></option>
									</select>
								</td>
							</tr>
							<tr class="repeats row">
								<th class="col-lg-3"><spring:message code="calendar.repeatsevery" text="Repete a cada"/></th>
								<td class="col-lg-9">
									<select name="" id="repeatsevery">
									</select>
									<label id="repeatsevery-label"><spring:message code="calendar.repeatsevery.days" text="Dias"/></label>
								</td>
							</tr>
							<tr id="repeatsconfig" class="repeats row">
							</tr>
							<tr class="row">
								<th class="col-lg-2"><spring:message code="calendar.summary" text="Resumo"/></th>
								<td class="col-lg-9" id="summary"></td>
							</tr>
					</table>
				</div>
			    <div class="modal-footer">
			      <button type="button" class="btn btn-default" data-dismiss="modal"><spring:message code="calendar.close" text="Fechar"/></button>
			      <button type="button" id="delete" class="btn btn-danger"><spring:message code="calendar.delete" text="Apagar"/></button>
			      <button type="button" class="btn btn-primary" id="save"><spring:message code="calendar.save" text="Guardar alterações"/></button>
			    </div>
    		</div>
	  	</div>
	</div>
	
</body></html>

