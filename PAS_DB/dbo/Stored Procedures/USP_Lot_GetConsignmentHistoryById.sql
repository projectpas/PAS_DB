

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
**************************************************************  
EXEC USP_Lot_GetConsignmentHistoryById 12  
**************************************************************/  
CREATE      PROCEDURE [dbo].[USP_Lot_GetConsignmentHistoryById]   
@ConsignmentId bigint =0  
AS  
BEGIN  
--[dbo].[USP_Lot_GetConsignmentSetupById]  10  
  SET NOCOUNT ON;  
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
  BEGIN TRY  
  BEGIN TRANSACTION  
 BEGIN          
  IF (@ConsignmentId >0)  
  BEGIN  
  SELECT DISTINCT
	   LC.ConsignmentAuditId
      ,LT.[LotId] LotId  
      ,LC.ConsignmentId  
      ,UPPER(LT.LotNumber) LotNumber  
      ,UPPER(LT.LotName) LotName  
      ,LC.[CreatedDate] CreatedDate  
      , (CASE WHEN ISNULL(lc.IsRevenue,0) = 1 THEN 'REVENUE' WHEN ISNULL(lc.IsMargin,0) = 1 THEN 'MARGIN' WHEN ISNULL(lc.IsFixedAmount,0) = 1 THEN 'FIXED AMOUNT' ELSE '' END) HowCalculate  
      --,ISNULL(LC.PerAmount,0.00)CalculateValue  
      ,(CASE WHEN ISNULL(LC.IsFixedAmount,0) = 1 THEN ISNULL(LC.PerAmount,0.00) ELSE (SELECT ISNULL(PercentValue,0) FROM DBO.[Percent] P WITH(NOLOCK) WHERE P.PercentId = ISNULL(LC.PercentId,0)) END) AS CalculateValue  
      ,UPPER(LC.ConsignmentNumber)ConsignmentNumber  
      ,UPPER(LC.ConsigneeName)ConsigneeName  
       ,UPPER(LC.ConsignmentName)ConsignmentName  
      ,LC.[MasterCompanyId]  
      ,LC.[CreatedBy]  
      ,ISNULL(lc.IsFixedAmount,0)AS IsFixedAmount
	  ,LC.[UpdatedDate] UpdatedDate
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