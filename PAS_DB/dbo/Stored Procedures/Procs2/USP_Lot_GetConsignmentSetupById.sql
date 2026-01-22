/*************************************************************           
 ** File:   [USP_Lot_GetConsignmentSetupById]           
 ** Author: Rajesh Gami
 ** Description: This stored procedure is used to Get Lot Setup By Id
 ** Date:   01/08/2023
 ** PARAMETERS:           
 ** RETURN VALUE:
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author  		Change Description            
 ** --   --------     -------		---------------------------     
    1   01/08/2023  Rajesh Gami     Created
**************************************************************
EXEC USP_Lot_GetConsignmentSetupById 2
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_Lot_GetConsignmentSetupById] 
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
			 LT.ConsignmentId
			,UPPER(ISNULL(LT.ConsignmentName,'')) ConsignmentName
			,L.LotId
			,ISNULL(LT.IsRevenue,0)IsRevenue
			,ISNULL(LT.IsMargin,0)IsMargin
			,ISNULL(LT.IsFixedAmount,0)IsFixedAmount
		    ,LT.MasterCompanyId
		    ,UPPER(L.LotName) LotName
		    ,UPPER(L.LotNumber) LotNumber
		    ,UPPER(LT.ConsigneeName) ConsigneeName
		    ,UPPER(LT.ConsignmentNumber) ConsignmentNumber
		    ,ISNULL(LT.PercentId,0)PercentId
		    ,ISNULL(LT.PerAmount,0)PerAmount
			,ISNULL(LT.ConsigneeTypeId,0)ConsigneeTypeId
			,ISNULL(LT.ConsigneeId,0)ConsigneeId
			,ISNULL(LT.IsRevenueSplit,0)IsRevenueSplit
			,ISNULL(LT.ConsignorPercentId,0)ConsignorPercentId
            FROM dbo.LotConsignment LT WITH (NOLOCK)
			INNER JOIN dbo.LOT L WITH(NOLOCK) on LT.LotId = L.LotId
			
		 WHERE LT.ConsignmentId = @ConsignmentId AND ISNULL(LT.IsDeleted,0) = 0 AND ISNULL(LT.IsActive,1) = 1
		  
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
            ,@AdhocComments varchar(150) = '[USP_Lot_GetConsignmentSetupById]',
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