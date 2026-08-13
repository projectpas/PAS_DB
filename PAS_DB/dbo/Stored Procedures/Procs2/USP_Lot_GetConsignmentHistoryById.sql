
/*************************************************************
 ** File:   [USP_Lot_GetConsignmentHistoryById]
 ** Author: Shrey Chandegara
 ** Description: This stored procedure is used to Get History Of Consignment
 ** Date:   16/08/2023
 ** PARAMETERS:
 ** RETURN VALUE:
 **************************************************************
  ** Change History
 **************************************************************
 ** PR   Date         Author    Change Description
 ** --   --------     -------  ---------------------------
    1   01/08/2023  Shrey Chandegara     Created
    2   11/08/2026  Nakul               Replaced HowCalculate/CalculateValue with per-method columns (IsRevenue/RevenuePercentage, IsMargin/MarginPercentage, IsFixedAmount/Amount) so each audit entry is a single row showing all configured methods
**************************************************************
EXEC USP_Lot_GetConsignmentHistoryById 12
**************************************************************/
CREATE PROCEDURE [dbo].[USP_Lot_GetConsignmentHistoryById]
@ConsignmentId bigint =0,
@EmployeeId bigint
AS
BEGIN
--[dbo].[USP_Lot_GetConsignmentSetupById]  10
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY
  BEGIN TRANSACTION
 BEGIN
 DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';

				SELECT
						@CurrntEmpTimeZoneDesc = COALESCE(
							ETZ.[Description],  -- Prefer Employee's TimeZone description if available
							LTZ.[Description]   -- Fallback to LegalEntity's TimeZone description
						)
					FROM
						dbo.Employee E WITH (NOLOCK)
					LEFT JOIN
						dbo.TimeZone ETZ WITH (NOLOCK)
						ON E.TimeZoneId = ETZ.TimeZoneId
					LEFT JOIN
						dbo.LegalEntity LE WITH (NOLOCK)
						ON E.LegalEntityId = LE.LegalEntityId
					LEFT JOIN
						dbo.TimeZone LTZ WITH (NOLOCK)
						ON LE.TimeZoneId = LTZ.TimeZoneId
					WHERE
						E.EmployeeId = @EmployeeId; -- Use appropriate filter for the specific employee

  IF (@ConsignmentId >0)
  BEGIN
  SELECT DISTINCT
	   LC.ConsignmentAuditId
      ,LT.[LotId] LotId
      ,LC.ConsignmentId
      ,UPPER(LT.LotNumber) LotNumber
      ,UPPER(LT.LotName) LotName
	  ,case when CAST(LC.[CreatedDate] as date) = CAST('0001-01-01 00:00:00' as date)then null else (Cast(DBO.ConvertUTCtoLocal(LC.[CreatedDate], @CurrntEmpTimeZoneDesc) as datetime))end CreatedDate
      ,ISNULL(LC.IsMargin,0) AS IsMargin
      ,(CASE WHEN ISNULL(LC.IsMargin,0) = 1 THEN (SELECT ISNULL(PercentValue,0) FROM DBO.[Percent] P WITH(NOLOCK) WHERE P.PercentId = ISNULL(LC.MarginPercentId,0)) ELSE NULL END) AS MarginPercentage
      ,ISNULL(LC.IsRevenue,0) AS IsRevenue
      ,(CASE WHEN ISNULL(LC.IsRevenue,0) = 1 THEN (SELECT ISNULL(PercentValue,0) FROM DBO.[Percent] P WITH(NOLOCK) WHERE P.PercentId = ISNULL(LC.PercentId,0)) ELSE NULL END) AS RevenuePercentage
      ,ISNULL(LC.IsFixedAmount,0) AS IsFixedAmount
      ,(CASE WHEN ISNULL(LC.IsFixedAmount,0) = 1 THEN ISNULL(LC.PerAmount,0.00) ELSE NULL END) AS Amount
      ,UPPER(LC.ConsignmentNumber)ConsignmentNumber
      ,UPPER(LC.ConsigneeName)ConsigneeName
       ,UPPER(LC.ConsignmentName)ConsignmentName
      ,LC.[MasterCompanyId]
      ,LC.[CreatedBy]
	  ,case when CAST(LC.[UpdatedDate] as date) = CAST('0001-01-01 00:00:00' as date)then null else (Cast(DBO.ConvertUTCtoLocal(LC.[UpdatedDate], @CurrntEmpTimeZoneDesc) as datetime))end UpdatedDate
	  ,LC.[updatedBy]
    FROM
    dbo.LotConsignmentAudit LC
    INNER JOIN [dbo].[Lot] LT WITH(NOLOCK) ON LC.LotId = LT.LotId
	WHERE LC.ConsignmentId = @ConsignmentId
	ORDER BY LC.ConsignmentAuditId DESC

  END
 END
 COMMIT  TRANSACTION
  END TRY
  BEGIN CATCH
  IF @@trancount > 0
   PRINT 'ROLLBACK'
   ROLLBACK TRAN;
  DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,@AdhocComments varchar(150) = '[USP_Lot_GetConsignmentHistoryById]',
            @ProcedureParameters varchar(3000) = '@ConsignmentId = ''' + CAST(ISNULL(@ConsignmentId, '') AS varchar(100)),
            @ApplicationName varchar(100) = 'PAS'
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
    EXEC spLogException @DatabaseName = @DatabaseName,
                        @AdhocComments = @AdhocComments,
                        @ProcedureParameters = @ProcedureParameters,
                        @ApplicationName = @ApplicationName,
                        @ErrorLogID = @ErrorLogID OUTPUT;
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
    RETURN (1);
  END CATCH
END