// assets/js/hooks/datepicker.js
import flatpickr from "flatpickr";

const holidays = [
  "2025-01-01", // New Year
  "2025-05-01", // Labor Day
  "2025-06-01", // Madaraka Day
  "2025-10-10", // Utamaduni Day
  "2025-10-20", // Mashujaa Day
  "2025-12-25", // Christmas
  "2025-12-26", // Boxing Day
];

const DatePickerHook = {
  mounted() {
    flatpickr(this.el, {
      dateFormat: "Y-m-d",
      altInput: true, // User-friendly format
      altFormat: "F j, Y", // Example: "February 21, 2025"
      allowInput: true, // Allow selection
      onDayCreate: function (dObj, dStr, fp, dayElem) {
        let date = dayElem.dateObj;

        if (date.getDay() === 6 || date.getDay() === 0) {
          // Gray out weekends
          dayElem.classList.add("weekend-day");
        }

        if (holidays.includes(date.toISOString().split("T")[0])) {
          // Gray out holidays
          dayElem.classList.add("holiday-day");
        }
      },
    });
  },
};

export default DatePickerHook;
