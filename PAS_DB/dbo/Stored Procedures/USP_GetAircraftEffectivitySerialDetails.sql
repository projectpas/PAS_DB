/*************************************************************
** Author:  Amit Ghediya
** Create date: 07/10/2026

** Description: Returns the "affects" (Individual/Range) and "except"
**              (exclusion) serial entries, for both Aircraft and Component,
**              for a single Aircraft Effectivity rule, so the Serial
**              Number Selector modal can pre-populate when reopened.
**
** Change History
************************************************************
** PR   Date         Author          Description
** --   ----------   -------------   -------------------------
** 1    14/07/2026  Amit Ghediya      Created
************************************************************/
CREATE PROCEDURE [dbo].[USP_GetAircraftEffectivitySerialDetails]
    @AircraftEffectivityId BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        AircraftEffectivitySerialDetailId,
        IsAircraftSerialNum,
        IsAffect,
        SerialType,
        FromSerial,
        ToSerial
    FROM dbo.AircraftEffectivitySerialDetail WITH (NOLOCK)
    WHERE AircraftEffectivityId = @AircraftEffectivityId
      AND IsDeleted             = 0
    ORDER BY IsAffect DESC, AircraftEffectivitySerialDetailId;

END