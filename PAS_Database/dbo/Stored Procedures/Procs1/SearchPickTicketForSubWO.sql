﻿/*************************************************************           
 ** File:   [SearchPickTicketForSubWO]           
 ** Author:   Hemant Saliya
 ** Description: This stored procedure is used Search Pick Ticket Details  
 ** Purpose:         
 ** Date:   05/25/2021        
          
 ** PARAMETERS:           
 @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    05/25/2021   Hemant Saliya Created
     
-- EXEC [SearchPickTicketForSubWO] 15,4,92,122
**************************************************************/
CREATE PROCEDURE [dbo].[SearchPickTicketForSubWO]
	@ItemMasterId BIGINT, 
	@ConditionId BIGINT,
	@WorkOrderId BIGINT,
	@StocklineId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				SELECT DISTINCT
					im.PartNumber
					,sl.StockLineId
					,im.ItemMasterId As PartId
					,im.ItemMasterId As ItemMasterId
					,im.PartDescription AS Description
					,ig.Description AS ItemGroup
					,mf.Name AS Manufacturer
					,ISNULL(im.ManufacturerId, -1) AS ManufacturerId
					,c.ConditionId
					,'' AlternateFor
					,CASE 
						WHEN im.IsPma = 1 and im.IsDER = 1 THEN 'PMA&DER'
						WHEN im.IsPma = 1 and im.IsDER = 0 THEN 'PMA'
						WHEN im.IsPma = 0 and im.IsDER = 1 THEN 'DER'
						ELSE 'OEM'
					END AS StockType
					,sl.StockLineNumber 
					,sl.SerialNumber
					,sl.ControlNumber
					,sl.IdNumber
					,ISNULL(wom.QuantityReserved,0) AS QtyToReserve
					,(ISNULL(wmsl.QtyReserved,0) + ISNULL(wmsl.QtyIssued,0)) - ISNULL((Select SUM(wopt.QtyToShip) from dbo.WorkorderPickTicket wopt WITH(NOLOCK) WHERE wopt.WorkOrderMaterialsId = wom.WorkOrderMaterialsId AND wmsl.StockLineId = wopt.StockLineId  ),0) AS QtyToPick
					,ISNULL(sl.QuantityAvailable,0) AS QtyAvailable
					,ISNULL(sl.QuantityOnHand, 0) AS QtyOnHand
					,ISNULL(sl.UnitCost, 0) AS unitCost
					,CASE WHEN sl.TraceableToType = 1 THEN cusTraceble.Name
							WHEN sl.TraceableToType = 2 THEN vTraceble.VendorName
							WHEN sl.TraceableToType = 9 THEN leTraceble.Name
							WHEN sl.TraceableToType = 4 THEN CAST(sl.TraceableTo as varchar)
					ELSE '' END AS TracableToName							 
					 ,sl.TagType
					 ,sl.TagDate
					 ,sl.CertifiedBy
					 ,sl.CertifiedDate
					 ,sl.Memo
					 ,'Stock Line' AS Method
					 ,'S' AS MethodType
					 ,CONVERT(BIT,0) AS PMA
					 ,Smf.Name as StkLineManufacturer
				FROM DBO.ItemMaster im WITH (NOLOCK)
					JOIN DBO.StockLine sl WITH (NOLOCK) ON im.ItemMasterId = sl.ItemMasterId AND sl.IsDeleted = 0 
						AND sl.ConditionId = CASE WHEN @ConditionId  IS NOT NULL THEN @ConditionId ELSE sl.ConditionId END
					LEFT JOIN DBO.WorkOrderMaterialStockLine wmsl WITH (NOLOCK) on wmsl.StockLineId = sl.StockLineId
					LEFT JOIN DBO.WorkOrderMaterials wom WITH (NOLOCK) on wom.WorkOrderMaterialsId = wmsl.WorkOrderMaterialsId
					LEFT JOIN DBO.WorkOrder wo WITH (NOLOCK) on wo.WorkOrderId = wom.WorkOrderId
					LEFT JOIN DBO.Condition c WITH (NOLOCK) ON c.ConditionId = sl.ConditionId
					LEFT JOIN DBO.ItemGroup ig WITH (NOLOCK) ON im.ItemGroupId = ig.ItemGroupId
					LEFT JOIN DBO.Manufacturer mf WITH (NOLOCK) ON im.ManufacturerId = mf.ManufacturerId
					LEFT JOIN DBO.Customer cusTraceble WITH (NOLOCK) ON sl.TraceableTo = cusTraceble.CustomerId
					LEFT JOIN DBO.Vendor vTraceble WITH (NOLOCK) ON sl.TraceableTo = vTraceble.VendorId
					LEFT JOIN DBO.LegalEntity leTraceble WITH (NOLOCK) ON sl.TraceableTo = leTraceble.LegalEntityId
					LEFT JOIN DBO.WorkorderPickTicket Pick WITH (NOLOCK) ON Pick.WorkOrderMaterialsId = wom.WorkOrderMaterialsId
					LEFT JOIN (SELECT ItemMasterId, [Name],StockLineId FROM DBO.Stockline S WITH (NOLOCK)
					INNER JOIN DBO.Manufacturer M WITH (NOLOCK) ON M.ManufacturerId = S.ManufacturerId) Smf ON Smf.ItemMasterId = im.ItemMasterId 
							AND Smf.StockLineId = sl.StockLineId
				WHERE im.ItemMasterId = @ItemMasterId AND wo.WorkOrderId=@WorkOrderId AND sl.StockLineId = @StocklineId
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'SearchStockLinePickTicketPop_WO' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkOrderId, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName           =  @DatabaseName
                     , @AdhocComments          =  @AdhocComments
                     , @ProcedureParameters	   =  @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID             =  @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END