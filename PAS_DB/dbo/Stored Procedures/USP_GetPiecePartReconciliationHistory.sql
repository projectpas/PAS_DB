/*************************************************************             
 ** File:   [USP_GetPiecePartReconciliationHistory]             
 ** Author:   Abhishek Jirawla   
 ** Description: Get Piece part Reconcile History
 ** Purpose:           
 ** Date:   22/06/2026	       
            
 ** PARAMETERS:             
     
 ** RETURN VALUE:             
    
 **************************************************************             
  ** Change History             
 **************************************************************             
  ** S NO   Date            Author				Change Description              
  ** --   --------			-------				--------------------------------            
     1    22/06/2026		Abhishek Jirawla	Created
 **************************************************************/  
 CREATE   PROCEDURE [dbo].[USP_GetPiecePartReconciliationHistory]
    @RepairOrderPartRecordId    BIGINT,
    @MasterCompanyId            INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

    SELECT
        ppr.PiecePartReconciliationId,
        ppr.RepairOrderPartRecordId,

        -- Source RO (where piece part lives)
        ppr.SourceRepairOrderId,
        srcRO.RepairOrderNumber     AS SourceRONumber,

        -- Consumed RO (where it was actually used)
        ppr.ConsumedRepairOrderId,
        conRO.RepairOrderNumber     AS ConsumedRONumber,

        -- Piece part identity
        rop.PartNumber,
        rop.PartDescription,
        rop.Condition,

        -- Vendor
        srcRO.VendorName,
        srcRO.VendorCode,

        -- Quantities at time of reconciliation
        ppr.QtyShipped,
        ppr.QtyConsumed,
        ppr.QtyReturned,
        ppr.QtyRemaining,

        ppr.ReconciliationStatus,
        ppr.Memo,

        -- Audit
        ppr.CreatedBy,
        ppr.CreatedDate,
        ppr.UpdatedBy,
        ppr.UpdatedDate
    FROM  dbo.PiecePartReconciliation  ppr WITH (NOLOCK)
    JOIN  dbo.RepairOrderPart          rop   WITH (NOLOCK) ON rop.RepairOrderPartRecordId = ppr.RepairOrderPartRecordId
    JOIN  dbo.RepairOrder              srcRO WITH (NOLOCK) ON srcRO.RepairOrderId         = ppr.SourceRepairOrderId
    LEFT JOIN dbo.RepairOrder          conRO WITH (NOLOCK) ON conRO.RepairOrderId         = ppr.ConsumedRepairOrderId
    WHERE ppr.RepairOrderPartRecordId = @RepairOrderPartRecordId
      AND ppr.MasterCompanyId         = @MasterCompanyId
      AND ppr.IsDeleted               = 0
    ORDER BY ppr.CreatedDate DESC;

    END TRY
   BEGIN CATCH
       

        DECLARE @ErrorLogID int,  
            @DatabaseName varchar(100) = DB_NAME()  
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            ,  
            @AdhocComments varchar(150) = '[USP_GetPiecePartReconciliationHistory]',  
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@RepairOrderPartRecordId, '') AS varchar(100)),
            @ApplicationName varchar(100) = 'PAS' 
        -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
        EXEC Splogexception @DatabaseName = @DatabaseName,  
                            @AdhocComments = @AdhocComments,  
                            @ProcedureParameters = @ProcedureParameters,  
                            @ApplicationName = @ApplicationName,  
                            @ErrorLogID = @ErrorLogID OUTPUT;  
  
        RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)  
  
        RETURN (1);  
    END CATCH
END