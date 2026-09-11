
/*****************************************************************************************
  ** File:        [fn_GetDaysForMonths]
  ** Description: Converts a number of months into its day-equivalent, measured from a
  **              reference date (@NextScheduledMaintenance) out to that many months later.
  **              If no reference date is supplied, falls back to today (GETUTCDATE()).
  **              Used by USP_CreateUpdateAircraftMaintenanceProgram to convert a "Months"
  **              based Time Limit (FlightHoursLimitMonthsOrDays = 1) into days, anchored to
  **              the program's Next Scheduled Maintenance date, so it can be
  **              compared/subtracted against TimeRecorded on a consistent (day) basis.
  ** Change History
  ** --------------------------------------------------------------------------------------
  ** PR       Date            Author                Change Description
  ** --       ----------      -------               ---------------------------------------------
              08/09/2026      Kishor Makwana        [PN-17374] - Created
              
*****************************************************************************************/
CREATE   FUNCTION [dbo].[fn_GetDaysForMonths]
(
    @NoOfMonths               INT,
    @NextScheduledMaintenance DATETIME2(7) = NULL
)
RETURNS INT
AS
BEGIN
    DECLARE @Days INT;
    DECLARE @FromDate DATETIME2(7) = ISNULL(@NextScheduledMaintenance, GETUTCDATE());

    SET @Days = DATEDIFF(DAY, @FromDate, DATEADD(MONTH, @NoOfMonths, @FromDate));

    RETURN @Days;
END