/*************************************************************            
 ** File:   [USP_GetWorkOrderHeaderView]           
 ** Author:   Ayushi Patel
 ** Description: This stored procedure retrieves work order header details by WorkOrderId.
 ** Purpose:         
 ** Date:   26/03/2025    
          
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date             Author		          Change Description            
 ** --   --------         -------		      ----------------------------       
    1    26/03/2025      Ayushi Patel           Created
	2    26/03/2026      Moin Bloch	            Rename TearDown To Internal Teardown PN-15850

	exec [USP_GetWorkOrderHeaderView] 8511
**************************************************************/

CREATE   PROCEDURE [dbo].[USP_GetWorkOrderHeaderView]
    @WorkOrderId BIGINT
AS
BEGIN	
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    SET NOCOUNT ON;

    BEGIN TRY
        DECLARE @ReferenceNo NVARCHAR(255) = '', 
                @WorkScope NVARCHAR(255) = '', 
                @ManagementStructureId BIGINT = 0;
        DECLARE @CustomerTypeId INT = ( SELECT TOP 1 Id FROM DBO.WorkOrderType WITH (NOLOCK) WHERE Description = 'Customer' );
        DECLARE @InternalTypeId INT = ( SELECT TOP 1 Id FROM DBO.WorkOrderType WITH (NOLOCK) WHERE Description = 'Internal Repair' );
        DECLARE @TeardownTypeId INT = ( SELECT TOP 1 Id FROM DBO.WorkOrderType WITH (NOLOCK) WHERE Description = 'Internal Teardown' );

        IF EXISTS (SELECT 1 FROM dbo.WorkOrder WITH (NOLOCK) WHERE ISNULL(IsSinglePN, 0) = 1)
        BEGIN
            SELECT TOP 1 
                @ReferenceNo = wop.CustomerReference,
                @WorkScope = wos.Description,
                @ManagementStructureId = wop.ManagementStructureId
            FROM dbo.WorkOrder wo WITH (NOLOCK)
            JOIN dbo.WorkOrderPartNumber wop WITH (NOLOCK) ON wo.WorkOrderId = wop.WorkOrderId
            JOIN dbo.WorkScope wos WITH (NOLOCK) ON wop.WorkOrderScopeId = wos.WorkScopeId
            WHERE wo.WorkOrderId = @WorkOrderId AND ISNULL(wop.IsDeleted,0) = 0;
        END;

        BEGIN TRANSACTION;
        
        SELECT 
            CASE 
                WHEN ISNULL(wo.IsSinglePN,0) = 1 THEN 'Single MPN' 
                ELSE 'Multiple MPN' 
            END AS SingleMPN,
            CASE 
                WHEN wo.WorkOrderTypeId = @CustomerTypeId THEN 'Customer WO'
                WHEN wo.WorkOrderTypeId = @InternalTypeId THEN 'Internal Repair WO'
                WHEN wo.WorkOrderTypeId = @TeardownTypeId THEN 'Internal Teardown WO'
                ELSE 'Shop Services WO' 
            END AS WorkOrderType,
            wo.WorkOrderNum AS WorkOrderNumber,
            c.Name AS CustomerName,
            wo.CreditLimit AS CreditTerm,
            ISNULL(wo.CreditLimit, 0) AS CreditLimit,
            wo.OpenDate,
            c.ContractReference,
            ISNULL(e.FirstName + ' ' + e.LastName, '') AS Employee,
            ISNULL(sp.FirstName + ' ' + sp.LastName, '') AS Salesperson,
            ws.Description AS WOStatus,
            c.CustomerCode,
            ISNULL(csr.FirstName + ' ' + csr.LastName, '') AS CSR,
            CASE WHEN ISNULL(wo.IsSinglePN,0) = 1 THEN wf.WorkFlowWorkOrderId ELSE 0 END AS WorkFlowWorkOrderId,
            CASE WHEN ISNULL(wo.IsSinglePN,0) = 1 THEN wf.WorkflowId ELSE 0 END AS WorkFlowId,
            wo.Notes,
            wo.Memo,
            CASE WHEN ISNULL(wo.IsSinglePN,0) = 1 THEN wf.WorkOrderPartNoId ELSE 0 END AS WOPartNoId,
            ISNULL(con.FirstName + ' ' + con.LastName, '') AS CustomerContact,
            ISNULL(con.WorkPhone + ' ' + con.WorkPhoneExtn, '') AS CustomerPhone,
            @ReferenceNo AS CustomerReference,
            @WorkScope AS WorkScope,
            @ManagementStructureId AS ManagementStructureId
        FROM dbo.WorkOrder wo WITH (NOLOCK)
        JOIN dbo.Customer c WITH (NOLOCK) ON wo.CustomerId = c.CustomerId
        LEFT JOIN dbo.Employee e WITH (NOLOCK) ON wo.EmployeeId = e.EmployeeId
        LEFT JOIN dbo.Employee sp WITH (NOLOCK) ON wo.SalesPersonId = sp.EmployeeId
        JOIN dbo.WorkOrderStatus ws WITH (NOLOCK) ON wo.WorkOrderStatusId = ws.Id
        JOIN dbo.WorkOrderWorkFlow wf WITH (NOLOCK) ON wo.WorkOrderId = wf.WorkOrderId
        LEFT JOIN dbo.Employee csr WITH (NOLOCK) ON wo.CSRId = csr.EmployeeId
        LEFT JOIN dbo.CustomerContact cc WITH (NOLOCK) ON wo.CustomerContactId = cc.CustomerContactId
        LEFT JOIN dbo.Contact con WITH (NOLOCK) ON cc.ContactId = con.ContactId
        WHERE wo.WorkOrderId = @WorkOrderId;

        COMMIT TRANSACTION;
    END TRY    
    BEGIN CATCH      
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorLogID INT, 
                @DatabaseName VARCHAR(100) = DB_NAME(),
                @AdhocComments VARCHAR(150) = 'USP_GetWorkOrderHeaderView',
                @ProcedureParameters VARCHAR(3000) = '@WorkOrderId = ' + CAST(@WorkOrderId AS NVARCHAR(50)),
                @ApplicationName VARCHAR(100) = 'PAS';

        EXEC spLogException 
             @DatabaseName = @DatabaseName,
             @AdhocComments = @AdhocComments,
             @ProcedureParameters = @ProcedureParameters,
             @ApplicationName = @ApplicationName,
             @ErrorLogID = @ErrorLogID OUTPUT;

        RAISERROR ('Unexpected error occurred. Please contact support with error number: %d', 16, 1, @ErrorLogID);
        RETURN (1);
    END CATCH;
END;