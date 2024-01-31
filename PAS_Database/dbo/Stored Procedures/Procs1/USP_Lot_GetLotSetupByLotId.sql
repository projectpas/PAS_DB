/*************************************************************           
 ** File:   [USP_Lot_GetLotSetupByLotId]           
 ** Author: Rajesh Gami
 ** Description: This stored procedure is used to Get Lot Setup By Id
 ** Date:   30/03/2023
 ** PARAMETERS:           
 ** RETURN VALUE:
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author  		Change Description            
 ** --   --------     -------		---------------------------     
    1    30/03/2023   Rajesh Gami     Created
**************************************************************
EXEC USP_Lot_GetLotSetupByLotId 53 
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_Lot_GetLotSetupByLotId] 
@LotId bigint =0
AS
BEGIN
--[dbo].[USP_Lot_GetLotSetupByLotId]  10
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY
  BEGIN TRANSACTION
	BEGIN			   		
		IF (@LotId >0)
		BEGIN
		SELECT DISTINCT
		    ISNULL(LS.LotSetupId,0)LotSetupId
		   ,LT.LotId
           ,ISNULL(LS.IsUseMargin,0) IsUseMargin
           ,ISNULL(LS.MarginPercentageId,0)MarginPercentageId
           ,ISNULL(LS.IsOverallLotCost,0)IsOverallLotCost
           ,ISNULL(LS.IsCostToPN,0)IsCostToPN
           ,ISNULL(LS.IsReturnCoreToLot,0)IsReturnCoreToLot
           ,ISNULL(LS.IsMaintainStkLine,0)IsMaintainStkLine
           ,ISNULL(LS.CommissionCost,0)CommissionCost
           ,LT.MasterCompanyId
           --,LS.CreatedBy
           --,LS.UpdatedBy
           --,LS.CreatedDate
           --,LS.UpdatedDate
		   --,UPPER(V.VendorName)VendorName
		   ,(Select top 1 ISNULL(ven.VendorName,'') from dbo.PurchaseOrder po WITH(NOLOCK) INNER JOIN dbo.Vendor ven WITH(NOLOCK) on po.VendorId = ven.VendorId Where po.PurchaseOrderId = Lt.InitialPOId AND ISNULL(po.IsDeleted,0) = 0) AS VendorName
		   ,UPPER(LT.LotName) LotName
		   ,UPPER(LT.LotNumber) LotNumber
		   ,UPPER(LC.ConsigneeName) ConsigneeName
		   ,UPPER(LC.ConsignmentNumber) ConsignmentNumber
		   ,( CASE WHEN ISNULL(LS.IsUseMargin,0) = 0 THEN 0 ELSE  ISNULL((SELECT Top 1 per.PercentValue FROM DBO.[Percent] per WITH(NOLOCK) WHERE per.percentId = ISNULL(LS.MarginPercentageId,0)),0) END) AS PercentValue
            FROM dbo.Lot LT WITH (NOLOCK)
			INNER JOIN dbo.LotDetail LD WITH(NOLOCK) ON LT.LotId = LD.LotId
			LEFT JOIN dbo.LotConsignment LC WITH(NOLOCK) ON lt.LotId = LC.LotId
			LEFT JOIN [dbo].[Vendor] V WITH(NOLOCK) ON LT.[VendorId] = V.[VendorId] 
			LEFT JOIN [dbo].[LotSetupMaster] LS WITH(NOLOCK) ON LT.LotId = LS.LotId

		 WHERE LT.LotId = @LotId AND ISNULL(LT.IsDeleted,0) = 0 AND ISNULL(LT.IsActive,1) = 1
		  
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
            ,@AdhocComments varchar(150) = '[USP_Lot_GetLotSetupByLotId]',
            @ProcedureParameters varchar(3000) = '@LotId = ''' + CAST(ISNULL(@LotId, '') AS varchar(100)),
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