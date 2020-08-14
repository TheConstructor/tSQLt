EXEC tSQLt.NewTestClass 'Private_ProcessTestAnnotationsTests';
GO
CREATE FUNCTION Private_ProcessTestAnnotationsTests.[return MyTestAnnotation](@TestObjectId INT)
RETURNS TABLE
AS
RETURN
  SELECT 1 AnnotationNo,'tSQLt.[@tSQLt:MyTestAnnotation]' Annotation;
GO
CREATE FUNCTION Private_ProcessTestAnnotationsTests.[return AnotherTestAnnotation](@TestObjectId INT)
RETURNS TABLE
AS
RETURN
  SELECT 1 AnnotationNo,'tSQLt.[@tSQLt:AnotherTestAnnotation]' Annotation;
GO
CREATE FUNCTION Private_ProcessTestAnnotationsTests.[return 3 Test Annotations](@TestObjectId INT)
RETURNS TABLE
AS
RETURN
  SELECT 1 AnnotationNo,'tSQLt.[@tSQLt:MyTestAnnotation1]' Annotation
  UNION ALL 
  SELECT 2 AnnotationNo,'tSQLt.[@tSQLt:MyTestAnnotation2]' Annotation
  UNION ALL 
  SELECT 3 AnnotationNo,'tSQLt.[@tSQLt:MyTestAnnotation3]' Annotation;
GO
CREATE PROCEDURE Private_ProcessTestAnnotationsTests.CreateMyTestAnnotations
AS
BEGIN
    EXEC('CREATE PROC tSQLt.[@tSQLt:MyTestAnnotation] AS RETURN 0;'); 
    EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.[@tSQLt:MyTestAnnotation]';
    EXEC('CREATE PROC tSQLt.[@tSQLt:AnotherTestAnnotation] AS RETURN 0;'); 
    EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.[@tSQLt:AnotherTestAnnotation]';
END
GO
CREATE PROCEDURE Private_ProcessTestAnnotationsTests.Create3DifferentTestAnnotations
AS
BEGIN
    EXEC('CREATE PROC tSQLt.[@tSQLt:MyTestAnnotation1] AS RETURN 0;'); 
    EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.[@tSQLt:MyTestAnnotation1]';
    EXEC('CREATE PROC tSQLt.[@tSQLt:MyTestAnnotation2] AS RETURN 0;'); 
    EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.[@tSQLt:MyTestAnnotation2]';
    EXEC('CREATE PROC tSQLt.[@tSQLt:MyTestAnnotation3] AS RETURN 0;'); 
    EXEC tSQLt.SpyProcedure @ProcedureName = 'tSQLt.[@tSQLt:MyTestAnnotation3]';
END
GO
CREATE PROCEDURE Private_ProcessTestAnnotationsTests.[test calls annotation procedure]
AS
BEGIN
  EXEC Private_ProcessTestAnnotationsTests.CreateMyTestAnnotations;
  EXEC tSQLt.FakeFunction 
         @FunctionName = 'tSQLt.Private_ListTestAnnotations', 
         @FakeFunctionName = 'Private_ProcessTestAnnotationsTests.[return MyTestAnnotation]';
  
  EXEC tSQLt.Private_ProcessTestAnnotations @TestObjectId = NULL;

  SELECT 1 WasCalled INTO #Actual FROM tSQLt.[@tSQLt:MyTestAnnotation_SpyProcedureLog];
  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected VALUES(1);
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
CREATE PROCEDURE Private_ProcessTestAnnotationsTests.[test calls another annotation procedure]
AS
BEGIN
  EXEC Private_ProcessTestAnnotationsTests.CreateMyTestAnnotations;
  EXEC tSQLt.FakeFunction 
         @FunctionName = 'tSQLt.Private_ListTestAnnotations', 
         @FakeFunctionName = 'Private_ProcessTestAnnotationsTests.[return AnotherTestAnnotation]';
  
  EXEC tSQLt.Private_ProcessTestAnnotations @TestObjectId = NULL;

  SELECT 1 WasCalled INTO #Actual FROM tSQLt.[@tSQLt:AnotherTestAnnotation_SpyProcedureLog];
  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected VALUES(1);
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
CREATE PROCEDURE Private_ProcessTestAnnotationsTests.[test calls all annotation procedures]
AS
BEGIN
  EXEC Private_ProcessTestAnnotationsTests.Create3DifferentTestAnnotations;
  EXEC tSQLt.FakeFunction 
         @FunctionName = 'tSQLt.Private_ListTestAnnotations', 
         @FakeFunctionName = 'Private_ProcessTestAnnotationsTests.[return 3 Test Annotations]';
  
  EXEC tSQLt.Private_ProcessTestAnnotations @TestObjectId = NULL;

  SELECT * 
    INTO #Actual
    FROM
    (
      SELECT 'MyTestAnnotation1' WasCalled FROM tSQLt.[@tSQLt:MyTestAnnotation1_SpyProcedureLog]
       UNION ALL
      SELECT 'MyTestAnnotation2' WasCalled FROM tSQLt.[@tSQLt:MyTestAnnotation2_SpyProcedureLog]
       UNION ALL
      SELECT 'MyTestAnnotation3' WasCalled FROM tSQLt.[@tSQLt:MyTestAnnotation3_SpyProcedureLog]
    )X;
  SELECT TOP(0) A.* INTO #Expected FROM #Actual A RIGHT JOIN #Actual X ON 1=0;
  INSERT INTO #Expected VALUES('MyTestAnnotation1'),('MyTestAnnotation2'),('MyTestAnnotation3');
  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO



-- allow for parameters in ()
-- can handle () or [] within parameter strings
-- brackets within annotation names are valid
-- spaces between ] and ( 
-- [InvalidAnnotation] invalid function name
-- [InvalidAnnotation] valid name that is not an annotation
-- [InvalidAnnotation] missing () at end
-- [InvalidAnnotation] missing ]
-- [InvalidAnnotation] mismatching parameter count
-- [InvalidAnnotation] additional characters (non-WS) after ")"
/*
 * --[@tSQLt:MyTestAnnotation] @SomeParameter=1
 * --[@tSQLt:ATestAnnotationWithoutParameters]
 * --[@tSQLt:SQLServerVersion] @MinVersion=2016, @MaxVersion=2019
 */